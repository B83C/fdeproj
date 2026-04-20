module tb_common #(
    parameter string TOP_MODULE = "design",
    parameter int CLOCK_HALF_PERIOD = 5
)();
    
    logic clk = 0;
    logic rst_n = 1;
    logic done;
    
    always #(CLOCK_HALF_PERIOD) clk = ~clk;
    
    initial begin
        done = 0;
        $dumpfile("waveform.fst");
        $dumpvars(0);
    end
    
    final begin
        $display("Simulation finished for %s", TOP_MODULE);
    end

endmodule