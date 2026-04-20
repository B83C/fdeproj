
#grid(
  columns: 1,
  rows: (1fr, 1fr, 1fr),
  align: center + horizon,
  image(width: 95%, "report_images/image1.jpeg"),
  image(width: 45%, "report_images/image2.jpeg"),
  text(size: 2em)[
    23300756003 刘恒雨 Law Heng Yi

    FDE Lab 0 & Lab 1 report

  ],
)

== Lab 0: Name display mock test
#figure(image("report_images/0.png"))
#figure(
  image("report_images/1.png"),
  caption: [Output waveform of the code in #link("https://surfer-project.org/", [#emph[surfer]]) with the ASCII output offset by -0x20 ],
)


#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#show: codly-init.with()

#codly(languages: codly-languages)

#{
  set text(size: 1em)
  columns(2, raw(read("../src/string_display/string_display.sv"), lang: "systemverilog", block: true))
}

== Lab 1: I2C ToF Digital Ruler

// This part explores the feasibility of designing flexible and easily infallible RTL design with the Spade Hardware Description Language which drew inspiration from the Rust programming language.

// As a long-time rust programmer, I have always been fascinated by the language itself. I have always appreciated the stringent rules that Rust imposes on the memory model which ensured memory safety and thus more stable and production-ready code. Spade


#show regex("(?i)I2C"): [I#super[2]C]


This project studies the implementation of i2c with the use of the VL6810x Time-of-Flight sensor for measuring distance to obstacles.

#figure(image("report_images/vl6180x.webp"))

The overall setup is as follows:

#figure(image("report_images/setup.png"))

Two 2N7000 mosfets were used in place of the internal tri-state buffer. They work as open-drain driver on the i2c bus with the output pulled up to 3.3V. This allows one to hook up the input and output together, thus avoiding the need for tri-state buffer.

It is worth mentioning that the fpga architecture although the its descrption file advertises TBUF, I could not get it work in time, but for the future adventurers, I think this might be possible by amending the FDE tool.

#figure(image("report_images/7.png"))

All that is left is the communication with the device from the fpga and host side controls.

=== State machine
When the machine is started, it first executes a start up procedure to write configuration data to the device as suggested by the official documentation. #footnote[See datasheet here for reference: https://www.st.com/resource/en/datasheet/vl6180x.pdf]

Then, it will poll the device at a constant rate for distance retrieval. Though simpler techniques based on interrupt could be implemented, I simply did not have the time budget to further implement it.
Once the data is retrieved it will be polled again on the computer host side. Please be noted that, the logic uses the 30MHz clock signal provided by the onboard crystal, whlist the host side communicates with FPGA through the SMIMS interface at a lower frequency of 1000Hz or so (with a maximum of 50kHz).

#figure(image(width: 50%, "report_images/15.png"), caption: [Simplified overview of the system's state machine])


=== Implementation of custom i2c master controller
The state machine of the i2c machine together with an example waveform is shown below for illustration.

#figure(
  image("report_images/8.png"),
  caption: [Test waveform running the i2c controller, with two bytes (0xA5, 0xB6) followed by a restart request (see red line)],
)

The i2c state machine was written by dividing the SCL clock into for portions, anchored at the crests and troughs as depicted below:

#figure(image("report_images/10.png"))

As per the standard specification, the START condition is defined by SDA's negative edeg when SCL is high while the STOP condition is indicated by a positive edge. From the master perspective, it usually only has to handle events at the crests and troughs. In essence, a frequency of $4 times f_"SCL"$ is required for the internal counter to trigger these events.

#figure(
  image("report_images/11.png"),
  caption: [General i2c packet format#footnote[Image from https://www.nxp.com/docs/en/user-guide/UM10204.pdf]],
)

An i2c packet generally comes in 9 bits, the first 8 bits/byte define the data, whilst the 9th bit is used for packet acknowledgement. When a master writes to slave, the acknowledgement bit is signified by a pull to low by the slave, and vice versa when the master reads from the slave.

#figure(image("report_images/12.png"), caption: [General packet flow for reading a specific register on a slave])


In most implementations, the master addresses the slave by first writing the slave's 7-bit address followed  by a R\/W (R = 1, W = 0) bit. This RW bit tells the slave that it intends to perform either a read or write to the device. Generally, when one wishes to read from a register on the slave. They would first need to write the device's address in write mode, followed by the register address, a *repeated* start, then rewriting the device's address in read mode. The ownership of the SDA now turns to the slave, and the master starts receiving data.

The case for writing data would be much simpler:

#figure(image("report_images/13.png"))

Again, depending on the actual implementation of the protocol, some devices might allow burst read/write:

#figure(image("report_images/14.png"))

This is all allowable with my i2c master controller thanks to the flexiblity in the design .

#(
  columns(2)[
    #set text(size: 0.9em)

    ```systemverilog
    module i2c_m #(
        parameter SCL_FREQ = 400_000,
        parameter CLK_FREQ = 30_000_000
    ) (
        ...
        rw_t rw,
        input restart,

        output reg done,
        output reg ack_ready,
        output reg ack,

        input [7:0] mosi,
        input in_valid,

        output reg [7:0] miso,
        input out_ready,
        output reg out_valid,

        ...

    );
    ```
    #colbreak()
    Here,  rw controls the direction of read or write. It is worth noting that the rw here is decoupled from the address rw. It simply defines the direction of data flow.

    Done signals notifies the parent module that a transfer is done, and waits for the next command. If another operation (read/write) is ready, the controller can simply operate, otherwise it would halt and generate a STOP condition.

    The downside to this approach is a more involved operation for the added flexibility. However, it solves
  ]
)




=== Custom GUI Interface employing vlfd-rs
Originally started as a SW/HW co-design project, I wrote the entire stack myself in Rust, employing the vlfd-rs crate. The benefit is maximum flexibililty with host side communication and better integration with the entire software stack.

// === Modifications to the yosys script for automatically inferred block-rams and other convenient tooling.

=== Experimental Results

= Thoughts on the experiment
Throughout this experiment, I basically brushed up on my i2c design brain muscle cells. I have gone  through a lot of wondering why and how. But with the right toolchain and environment set up, I'd say I have circumsteppepd a lot of unrelated technicalities. I wrote my code fast and it runs fast, I have gone through thousands of trial and errors.

This experiment was way to tiring for me to conduct. I would say that I hit the wrong choice when I started this. Initially, I was going to implement fix TBUF mapping for yosys to allow inout ports definitios. My goal was to enable support for what should have already been support, but ended up in the rabbit hole of trying to fix everyting. This of course, caused be a ton of pain and suffering. I must admit that not every problem is worth solving. The hard part is remembering to do just "enough", and not to push to the very end. A 60% completion will take a day, but a 99% completion will take 99% effort and days of nightless sleep and toiling at dorm. I am enough of all these. Now let me complete this part, and move on to the next chapter of life.
