#import "@preview/typslides:1.3.3": *

#show regex("(?i)I2C"): [I#super[2]C]

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
  authors: "Law Heng Yi",
  info: [#link("https://github.com/manjavacas/typslides")],
)


#front-slide(
  title: "digital ruler with vl6180x using i2c",
  subtitle: [Lab 1],
  authors: "Law Heng Yi 23300756003",
  info: [#link("https://github.com/manjavacas/typslides")],
)

// Custom outline
#table-of-contents()

// Title slides create new sections
#title-slide[
  digital ruler with vl6180x using i2c
]

// A simple slide
#slide[
  - This is a simple `slide` with no title.
  - #stress("Bold and coloured") text by using `#stress(text)`.
  - Sample link: #link("typst.app").
    - Link styling using `link-style`: `"color"`, `"underline"`, `"both"`
  - Font selection using `font: "Fira Sans"`, `size: 21pt`.

  #framed[This text has been written using `#framed(text)`. The background color of the box is customisable.]

  #framed(title: "Frame with title")[This text has been written using `#framed(title:"Frame with title")[text]`.]
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

// Slide with title
#slide(title: "Some images of the experiment setup", outlined: true)[

]

#slide(title: "What I learned/done so far", outlined: true)[
  - Setting up implementation flow using yosys scripts
  - Brushed up on the implementation of i2c
  - Undergone the pain of making things work

  // - Check out the *progress bar* at the bottom of the slide.

  //   #h(1cm) `show-progress: true`

  // - Outline slides with `outlined: true`.

  // #grayed([This is a `#grayed` text. Useful for equations.])
  // #grayed($ P_t = alpha - 1 / (sqrt(x) + f(y)) $)

]

// Columns
#slide(title: "Columns")[

  #cols(columns: (2fr, 1fr, 2fr), gutter: 2em)[
    #grayed[Columns can be included using `#cols[...][...]`]
  ][
    #grayed[And this is]
  ][
    #grayed[an example.]
  ]

  - Custom spacing: `#cols(columns: (2fr, 1fr, 2fr), gutter: 2em)[...]`

    // - Sample references: @typst, @typslides.
    - Add a #stress[bibliography slide]...

    1. `#let bib = bibliography("you_bibliography_file.bib")`
    2. `#bibliography-slide(bib)`
]

#focus-slide[
  That's it.
  // This is an auto-resized _focus slide_.
]
