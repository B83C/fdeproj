
module string_display (
    (* pin = "P77" *) input  logic clk,
    input  logic rst_n,
    output logic       valid,
    output logic [7:0] char
);
    localparam display = "Fudan University  Law Heng Yi  \n";
    localparam [7:0] CHAR_OFFSET = 8'h20;
    localparam int LENGTH = 32;

    function [8*LENGTH-1:0] offset_string(input [8*LENGTH-1:0] s);
        for (int i = 0; i < LENGTH; i++) begin
            offset_string[8*i +: 8] = s[8*(LENGTH - 1 - i) +: 8] - CHAR_OFFSET;
        end
    endfunction

    localparam [8*LENGTH-1:0] LINE1 = offset_string(display);

    logic [4:0] index;
    assign valid = 0;
    assign char  = LINE1[8*index +: 8];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            index   <= '0;
        end else begin
            if (index == 5'(LENGTH - 1)) begin
                index <= '0;
            end else begin
                index <= index + 1'b1;
            end
        end
    end

endmodule
