`include "tb_common.sv"

module tb_tpm_aes;
    
    tb_common #(.TOP_MODULE("tpm_aes"), .CLOCK_HALF_PERIOD(5)) tb();
    
    wire clk = tb.clk;
    // wire rst = tb.rst_n;
    
    logic       out_valid;
    logic [7:0] out_data;
    logic       tick;
    
    tpm_aes uut (
        .clk       (clk),
        // .rst       (rst),
        // .out_valid (out_valid),
        .out_data  (out_data),
        .tick      (tick)
    );
    
    initial begin
        repeat(500) @(posedge clk);
        tb.done = 1;
        $finish;
    end
    
    logic tick_prev;
    always @(posedge clk) begin
        tick_prev <= tick;
        if (tick != tick_prev) begin
            $display("tick toggle: out_data = 0x%02h", out_data);
        end
    end

endmodule
