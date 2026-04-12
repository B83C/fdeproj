`include "tb_common.sv"

module tb_string_display;
    
    tb_common #(.TOP_MODULE("string_display"), .CLOCK_HALF_PERIOD(5)) tb();
    
    wire clk = tb.clk;
    wire rst_n = tb.rst_n;
    
    logic       valid;
    logic [7:0] char;
    
    string_display uut (
        .clk    (clk),
        .rst_n  (rst_n),
        .valid  (valid),
        .char   (char)
    );
    
    initial begin
        repeat(100) @(posedge clk);
        tb.done = 1;
        $finish;
    end
    
    always @(posedge clk) begin
        if (valid) begin
            $write("%c", char);
            if (char == 8'h00 || char == 8'h20)
                $write(".");
        end
    end

endmodule