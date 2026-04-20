
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
  columns(2, raw(read("../src/namedisplay/namedisplay.sv"), lang: "systemverilog", block: true))
}

#figure(image("report_images/19.png"), caption: [Name display output to console on custom program])
To facilitate programming, I wrote a program that utilises the vlfd-rs library for interacting directly with the SMIMS adapter.

#figure(
  ```rust
    let console_output = outputs.get("console_char[0]").cloned();
  ```,
  caption: [ Code to get the pin offset, located in *sw_interface/src/main.rs*],
)



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
    #colbreak()
    Here,  *rw* controls the direction of read or write. It is worth noting that the *rw* here is decoupled from the address *rw*. It simply defines the direction of data flow.

    *done* signals notifies the parent module that a transfer is done, and waits for the next command. If another operation (read/write) is ready, the controller can simply operate, otherwise it would halt and generate a STOP condition.

    The downside to this approach is more involved operations but for the added flexibility, it is worth it.

    To send data to the controller, one has to latch the data onto *mosi*, then sets *in_valid* accordingly. If there's any preceding unrelated transaction, one would need to set *restart* for current operation, and unset it before the done signal is asserted.

    The *halt* signal is interesting, since restart precedes the transaction whilst halt runs at last. This was used when long pause between transactions is needed.

  ]
)




=== Custom GUI Interface employing vlfd-rs
Originally started as a SW/HW co-design project, I wrote the entire stack myself in Rust, employing the vlfd-rs crate. The benefit is maximum flexibililty with host side communication and better integration with the entire software stack.
#figure(image(width: 50%, "report_images/18.png"), caption: [Custom GUI using vlfd-rs])

The interface (buttons and such) is constructed automatically based on the pins configuration file that is generated by a helper program that reads ports information from the top module.







// === Modifications to the yosys script for automatically inferred block-rams and other convenient tooling.

=== Experimental Results

#figure(image("report_images/16.png"), caption: [Start up waveform captured with ADALM2000 viewed in Scopy])

The machine warms up by firing to the i2c address (0x29, here 0x52 = 0x29 << 1) a command to check on the slave status. As shown above, it first writes to the register address 0x0036, to check if the slave is on frest start. In which case, it would then do the normal configuration flow. Afterwards, it starts reading the range value by issueing the following commands:

#figure(image("report_images/17.png"), caption: [Polling data on the range register])

The polling procedure is quite simple. Send a write request of 0x01 to the address 0x0018, then check on its readiness by inspecting 3rd LSB of the register 0x004F. If it is asserted, then data is ready to be read from the register 0x0062. According to the datasheet, the data returned is in milimeters.

#figure(
  grid(
    columns: 2,
    image("report_images/phone.jpeg"), image("report_images/phone2.jpeg"),
  ),
  caption: [Polling data on the range register],
)

The final result is as shown above. It might be confusing at first to see 70mm although my hands are not far from the sensor's aperture. The valid reasoning here is that the sensor is offset by some value (60mm here) as a result of lacking calibration. To verify, I nudged my finger slighly higher and it measured the delta distance just well enough. To conclude, the set up works.


= Thoughts on the experiment
Throughout this experiment, I basically brushed up on my i2c design brain muscle cells. I have gone  through a lot of wondering why and how. But with the right toolchain and environment set up, I'd say I have circumsteppepd a lot of unrelated technicalities.

In hindsight, I am still glad that I got this working despite the dire situation I have got into：Running into unknown errors when setting up my custom toolchain environment. And also running into weird errors due to the nature of simulated annealing. What I mean by that is, most of the time, the device would not operate at all when let's say I added a register to the design. Or that I changed a simple parameter. It is not some small noticable difference in the output, but it just stops clocking. Runs well in simulation, but turns out different. I still haven't got to understand why that would happen, but luck always get me through.

This experiment was way too tiring for me to conduct. Not because it is hard, but rather the matter of a good choice. I wanted to experiment with something cool but nothing was cool, and real cool stuff is limited by the resource. I was then turned to implementing a fix  for TBUF mapping  to allow the use of inout ports. But I actually ended up in the rabbit hole of trying to fix everyting. This of course, caused me a ton of pain and suffering. I must admit that not every problem is worth solving. The hard part is remembering to do just "enough", and not to push to the very end. A 60% completion will take a day, but a 99% completion will take 99% effort and days of nightless sleep and toiling at dorm. I am enough of all these. Now let me complete this part, and move on to the next chapter of life.
