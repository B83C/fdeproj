# top = main

from cocotb.triggers import FallingEdge

import cocotb
from spade import SpadeExt
from cocotb.clock import Clock


@cocotb.test()
async def simple_test(dut):
    s = SpadeExt(dut)

    clk = dut.clk_i  # Access the raw clock signal via the dut
    await cocotb.start(Clock(clk, 20, units="ns").start())
    await FallingEdge(clk)
    s.i.rst = True
    await FallingEdge(clk)
    s.i.rst = False

    for i in range(50):
        await FallingEdge(clk)
    # s.o.assert_eq("OutputControl::Ret()")
    # s.i.timing = """Timing$(
    #     us280: 28,
    #     us0_4: 4,
    #     us0_8: 8,
    #     us0_45: 4,
    #     us0_85: 8,
    #     us1_25: 12,
    # )"""
    # await FallingEdge(clk)
    # s.o.assert_eq("OutputControl::Ret()")
