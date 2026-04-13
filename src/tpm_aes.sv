module tpm_aes (
    input  logic        clk,
    output logic [7:0]  out_data,

    output logic        tick
);

    logic          tick_reg;
    logic [7:0]    count = 0;

    always_ff @(posedge clk) begin
        tick_reg <= ~tick_reg;
        
        // if (rst) begin
        //     count <= 0;
        // end else begin
        count <= count + 1;
        // end
        
        // out_valid <= 1;
        // out_data <= count;
    end
    assign out_data = count;

    assign tick = tick_reg;

endmodule
