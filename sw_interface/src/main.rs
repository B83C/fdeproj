#![feature(atomic_try_update)]
use bitvec::{
    access::BitAccess,
    field::BitField,
    index::{BitIdx, BitMask},
    prelude::*,
};
use eframe::{
    App,
    egui::{self, Button, Color32, Id, Layout, Pos2, RichText, Sense, Vec2, ahash::HashMap},
};
use log::{error, info};
use serde::{Deserialize, Serialize};
use serde_xml_rs::from_str;
use std::{
    env, fs,
    path::Path,
    sync::{
        Arc,
        atomic::{AtomicU32, AtomicU64, Ordering},
        mpsc::{Sender, channel},
    },
    thread::{JoinHandle, sleep, spawn},
    time::{Duration, Instant},
};
use vlfd_rs::{Board, IoConfig, load_bitfile};

use anyhow::{Context, Result};

fn main() -> Result<()> {
    env_logger::init();

    let _ = eframe::run_native(
        "FDE Programmer",
        eframe::NativeOptions {
            viewport: egui::ViewportBuilder::default()
                .with_inner_size([300.0, 300.0]) // initial
                .with_min_inner_size([200.0, 200.0])
                .with_resizable(false), // IMPORTANT: allows hugging behavior
            ..Default::default()
        },
        Box::new(|_| Ok(Box::new(HostApp::default()))),
    );
    Ok(())
}

const GRID_SIZE: usize = 16;
const FADE_MS: u64 = 500;

#[derive(Default)]
struct HostApp {
    worker: Option<(JoinHandle<()>, Sender<u64>)>,
    frequency: Arc<AtomicU32>,
    input: Arc<AtomicU64>,
    output: Arc<AtomicU64>,

    last_active: [[Option<Instant>; GRID_SIZE]; GRID_SIZE],
    now: Option<Instant>,
    state: u64,
    input_text: String,
    inputs: std::collections::HashMap<String, usize, egui::ahash::RandomState>,
    outputs: std::collections::HashMap<String, usize, egui::ahash::RandomState>,
}

#[derive(Clone)]
enum Status {
    Err(String),
    Success(String),
}

#[derive(Clone)]
enum DeviceState {
    Sending,
    AwaitResponse(u64),
    Idle,
}

#[derive(Debug, Deserialize)]
struct Design {
    #[serde(rename = "port")]
    ports: Vec<Port>,
}

#[derive(Debug, Deserialize)]
struct Port {
    #[serde(rename = "@name")]
    name: String,
    #[serde(rename = "@absolute_position")]
    absolute_position: Option<String>,
    #[serde(rename = "@type")]
    r#type: String,
}

impl App for HostApp {
    fn ui(&mut self, ui: &mut eframe::egui::Ui, _frame: &mut eframe::Frame) {
        let program_pressed =
            ui.input(|i| i.key_pressed(egui::Key::Enter) || i.key_pressed(egui::Key::Space));

        ui.style_mut()
            .text_styles
            .insert(egui::TextStyle::Body, egui::FontId::proportional(30.0));

        if ui.input(|i| i.key_down(egui::Key::Q)) {
            ui.ctx().send_viewport_cmd(egui::ViewportCommand::Close);
        }

        ui.vertical_centered(|ui| {
            ui.heading("TPM Aes Demo");
            ui.add_space(12.0);
            if self.worker.as_ref().is_none_or(|x| x.0.is_finished()) {
                let btn = ui.button("Program and connect");
                if btn.clicked() || program_pressed {
                    let ctx = ui.ctx().clone();
                    let freq = self.frequency.clone();
                    let input = self.input.clone();
                    let output = self.output.clone();
                    let (tx, rx) = channel::<u64>();

                    let set_status = {
                        let ctx = ctx.clone();
                        move |x| {
                            ctx.data_mut(|id_map| {
                                id_map.insert_temp(Id::new("Status"), x);
                            });
                            ctx.request_repaint();
                        }
                    };

                    let load_design = || -> Result<_> {
                        let pin_map =
                            std::env::var("PIN_MAP").unwrap_or("build/tpm_aes_cons.xml".into());

                        let design: Design = from_str(&fs::read_to_string(dbg!(pin_map))?)?;

                        let inputs = design
                            .ports
                            .iter()
                            .filter(|x| x.r#type == "input")
                            .filter_map(|x| {
                                // Accept simple names and only the first of vectors (assumming that array will be sequential)
                                if x.name.contains("[0]") || !x.name.contains("[") {
                                    x.absolute_position
                                        .as_ref()
                                        .map(|pos| {
                                            pos.parse::<usize>()
                                                .ok()
                                                .map(|pos| (x.name.clone(), pos))
                                        })
                                        .flatten()
                                } else {
                                    None
                                }
                            })
                            .collect::<HashMap<_, _>>();
                        let outputs = design
                            .ports
                            .iter()
                            .filter(|x| x.r#type == "output")
                            .filter_map(|x| {
                                // Accept simple names and only the first of vectors (assumming that array will be sequential)
                                if x.name.contains("[0]") || !x.name.contains("[") {
                                    x.absolute_position
                                        .as_ref()
                                        .map(|pos| {
                                            pos.parse::<usize>()
                                                .ok()
                                                .map(|pos| (x.name.clone(), pos))
                                        })
                                        .flatten()
                                } else {
                                    None
                                }
                            })
                            .collect::<HashMap<_, _>>();
                        Ok((inputs, outputs))
                    };

                    let env_freq = std::env::var("FREQ")
                        .map(|x| x.parse::<u32>().ok())
                        .ok()
                        .flatten()
                        .unwrap_or(1u32);
                    freq.store(env_freq, Ordering::Relaxed);

                    match load_design() {
                        Ok((inputs, outputs)) => {
                            let console_output = outputs.get("console_char[0]").cloned();
                            let id = spawn(move || {
                                let runner = || -> Result<()> {
                                    // dotenvy::dotenv()?;

                                    let bitstream_path = std::env::var("BITSTREAM")
                                        .unwrap_or("build/tpm_aes.bit".into());

                                    let mut board = Board::open()?;
                                    let bitstream = load_bitfile(Path::new(&bitstream_path))
                                        .expect("Unable to read bitstream");
                                    let mut programmer = board.programmer()?;
                                    programmer.write_bitstream_words(&bitstream)?;
                                    programmer.finish()?;
                                    info!("Done programming");
                                    let config = board.refresh_config()?;
                                    if config.is_programmed() {
                                        set_status(Status::Success(
                                            "Board has been successfully programmed".into(),
                                        ));
                                    }

                                    let mut io = board
                                        .configure_io(&IoConfig::default())
                                        .expect("Failed to configure IO");

                                    loop {
                                        let input =
                                            input.load(std::sync::atomic::Ordering::Relaxed);
                                        let mut out = 0u64;
                                        let input: [u16; 4] = bytemuck::cast(input);
                                        let rx: &mut [u16; 4] = bytemuck::cast_mut(&mut out);
                                        io.transfer_into(&input, rx)?;

                                        if let Some(console_bit) = console_output {
                                            let n = console_bit;
                                            let bits = rx.view_bits::<Lsb0>();
                                            print!("{}", bits[n..n + 8].load_le::<u8>() as char);
                                        }

                                        output.store(out, Ordering::Relaxed);

                                        let period = 1000000
                                            / freq
                                                .load(std::sync::atomic::Ordering::Relaxed)
                                                .clamp(1, 50_000);
                                        // ctx.request_repaint();

                                        sleep(Duration::from_micros(period.into()));
                                    }
                                };
                                if let Err(e) = runner() {
                                    set_status(Status::Err(e.to_string()));
                                }
                            });
                            self.worker = Some((id, tx));
                            self.inputs = inputs;
                            self.outputs = outputs;
                        }
                        Err(e) => set_status(Status::Err(e.to_string())),
                    }
                }
                ui.add_space(8.0);
                ui.label("Press Enter or space to program");
            } else {
                ui.horizontal(|ui| {
                    ui.add_space(20.0);
                    ui.add(
                        egui::Slider::from_get_set(1.0..=50_000f64, |val| {
                            let old = self
                                .frequency
                                .fetch_min(1, std::sync::atomic::Ordering::Relaxed)
                                as f64;
                            let val = val.unwrap_or(old);
                            self.frequency
                                .store(val as u32, std::sync::atomic::Ordering::Relaxed);
                            val
                        })
                        .text("Clock Frequency"),
                    );
                    ui.add_space(20.0);
                });

                if let Some(&c) = self.outputs.get("range[0]") {
                    let output = self.output.load(Ordering::Relaxed);
                    let range = output.view_bits::<Lsb0>()[c..c + 8].load_le::<u8>();
                    let string = format!("{} mm", range);
                    ui.label(RichText::new(string).color(Color32::ORANGE).size(30.0));
                }

                let mut input = self.input.load(Ordering::Relaxed);
                let input_bits = input.view_bits_mut::<Lsb0>();
                let mut should_update_input = false;

                for (name, idx) in self.inputs.iter()
                // .filter(|(n, _)| n.starts_with("key"))
                {
                    let send = ui.add(Button::new(name).sense(Sense::drag()));
                    let active_low = name.ends_with("_n");
                    if send.drag_started() {
                        should_update_input = true;
                        input_bits.set(*idx, !active_low);
                    } else if send.drag_stopped() {
                        should_update_input = true;
                        input_bits.set(*idx, active_low);
                    }
                }

                let cell_size = 20.0;
                let spacing = 6.0;

                let total_size = GRID_SIZE as f32 * (cell_size + spacing);

                // let (rect, _) = ui.allocate_exact_size(Vec2::splat(total_size), Sense::click());

                // let painter = ui.painter_at(rect);

                // if let Some(&c) = self.outputs.get("PIN_C[0]")
                //     && let Some(&r) = self.outputs.get("PIN_R[0]")
                // {
                //     let c_states: u16 = self.output.view_bits::<Lsb0>()[c..c + GRID_SIZE].load();
                //     let r_states: u16 = self.output.view_bits::<Lsb0>()[r..r + GRID_SIZE].load();
                //     let now = Instant::now();
                //     // self.now = Some(Instant::now());
                //     for y in 0..GRID_SIZE {
                //         for x in 0..GRID_SIZE {
                //             let pos = Pos2 {
                //                 x: rect.left_top().x + x as f32 * (cell_size + spacing),
                //                 y: rect.left_top().y + y as f32 * (cell_size + spacing),
                //             };

                //             let center = pos + Vec2::splat(cell_size / 2.0);

                //             let active =
                //                 c_states.view_bits::<Lsb0>()[x] && r_states.view_bits::<Lsb0>()[y];
                //             if active {
                //                 self.last_active[y][x] = Some(now);
                //             }
                //             let elapsed = self.last_active[y][x].map(|t| now.duration_since(t));
                //             let fade_time = 1.5;

                //             let intensity = elapsed
                //                 .map(|d| (1.0 - d.as_secs_f32() / fade_time).clamp(0.0, 1.0))
                //                 .unwrap_or(0.0);

                //             let gray = (80.0 + intensity * 175.0) as u8;
                //             let color = Color32::from_gray(gray);

                //             painter.circle_filled(center, cell_size / 2.0, color);
                //         }
                //     }
                // }

                if should_update_input {
                    self.input.store(input, Ordering::Relaxed);
                }

                // ui.add(
                //     egui::TextEdit::singleline(&mut self.input_text)
                //         .hint_text("String to be encrypted"),
                // );
            }
            let data = ui
                .ctx()
                .data(|id_map| id_map.get_temp::<Status>(Id::new("Status")));
            if let Some(data) = data {
                let (data, c) = match data {
                    Status::Err(e) => (e, Color32::RED),
                    Status::Success(e) => (e, Color32::GREEN),
                };
                ui.label(RichText::new(data).color(c));
            }
        });
        ui.ctx()
            .request_repaint_after(std::time::Duration::from_millis(33));
    }
}
