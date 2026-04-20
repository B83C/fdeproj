#import "@preview/typslides:1.3.3": *

#show regex("(?i)I2C"): [I#super[2]C]
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#show: codly-init.with()

#codly(languages: codly-languages)


// Project configuration
#show: typslides.with(
  ratio: "16-9",
  theme: "bluey",
  font: "Fira Sans",
  font-size: 20pt,
  link-style: "color",
  show-progress: true,
)

// The front slide is the first slide of your presentation
#front-slide(
  title: "Name Display",
  subtitle: [Lab 0],
  authors: "Law Heng Yi 23300756003",
  // info: [#link("https://github.com/manjavacas/typslides")],
)

#slide[
  #figure(image("report_images/19.png"), caption: [Name display output to console on custom program])
  To facilitate programming, I wrote a program that utilises the vlfd-rs library for interacting directly with the SMIMS adapter.

  #figure(
    ```rust
      let console_output = outputs.get("console_char[0]").cloned();
    ```,
    caption: [ Code to get the pin offset, located in *sw_interface/src/main.rs*],
  )
]


#front-slide(
  title: "digital ruler with vl6180x using i2c",
  subtitle: [Lab 1],
  authors: "Law Heng Yi 23300756003",
  info: [#link("https://github.com/b83c/fdeproj")],
)

// Custom outline
// #table-of-contents()

// Title slides create new sections
#title-slide[
  The vl6180x ToF Sensor Module
  #figure(image(width: 60%, "report_images/vl6180x.webp"))
]

// A simple slide
#slide[
  #figure(image("report_images/setup.png"))
  // - This is a simple `slide` with no title.
  // - #stress("Bold and coloured") text by using `#stress(text)`.
  // - Sample link: #link("typst.app").
  //   - Link styling using `link-style`: `"color"`, `"underline"`, `"both"`
  // - Font selection using `font: "Fira Sans"`, `size: 21pt`.

  // #framed[This text has been written using `#framed(text)`. The background color of the box is customisable.]

  // #framed(title: "Frame with title")[This text has been written using `#framed(title:"Frame with title")[text]`.]
]

// Blank slide
// #blank-slide[
//   - This is a `#blank-slide`.

//   - Available #stress[themes]#footnote[Use them as *color* functions! e.g., `#reddy("your text")`]:

//   #framed(back-color: white)[
//     #bluey("bluey"), #reddy("reddy"), #greeny("greeny"), #yelly("yelly"), #purply("purply"), #dusky("dusky"), darky.
//   ]

// #show: typslides.with(
//   ratio: "16-9",
//   theme: "bluey",
//   ...
// )


//   - Or just use *your own theme color*:
//     - `theme: rgb("30500B")`
// ]

#slide[

  #figure(image(width: 50%, "report_images/15.png"), caption: [Simplified overview of the system's state machine])
]

#slide[

  #columns(2)[
    #set text(size: 0.6em)

    ```systemverilog
    module i2c_m #(
        parameter SCL_FREQ = 400_000,
        parameter CLK_FREQ = 30_000_000
    ) (
        ...
        rw_t rw,
        input restart,
        input halt,

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
    #set text(size: 18pt)
    - RW: Read write direction
    - Restart：Restart before subsequent transaction
    - Halt: STOP after the current transaction

    - Benefits:
      + Maximum flexibility

    - Drawback:
      + More involved and requirement on the implementation side

    #colbreak()
  ]
  #figure(image(width: 50%, "report_images/18.png"), caption: [Custom GUI using vlfd-rs])
]
// Slide with title
#slide(title: "Some images of the experiment setup", outlined: true)[
  #figure(
    grid(
      columns: 2,
      image("report_images/phone.jpeg"), image("report_images/phone2.jpeg"),
    ),
    caption: [Polling data on the range register],
  )
]

#slide(title: "What I learned/done so far", outlined: true)[
  - Set up custom implementation flow using yosys scripts
  - Brushed up on the implementation of i2c
  - Made automatically inferred BRAM work with the latest yosys
  - Understood the basic flow of packing everything up into bitstream
  - Undergone the pain of making things work
  - Learn to give up on unnecessary details
]

// Columns
// #slide(title: "Columns")[

//   #cols(columns: (2fr, 1fr, 2fr), gutter: 2em)[
//     #grayed[Columns can be included using `#cols[...][...]`]
//   ][
//     #grayed[And this is]
//   ][
//     #grayed[an example.]
//   ]

//   - Custom spacing: `#cols(columns: (2fr, 1fr, 2fr), gutter: 2em)[...]`

//     // - Sample references: @typst, @typslides.
//     - Add a #stress[bibliography slide]...

//     1. `#let bib = bibliography("you_bibliography_file.bib")`
//     2. `#bibliography-slide(bib)`
// ]

#focus-slide[
  That's it.

  Thanks for listening
  // This is an auto-resized _focus slide_.
]
