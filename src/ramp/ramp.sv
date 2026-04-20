module ramp (
    (* pin = "P185" *) input clk,
    input reset_n,

    output [7:0] plot_distance
);

    localparam DIVISOR = 586;

    logic [15:0] counter;
    logic [7:0] ramp_data;

    always_ff @(posedge clk) begin
        if (!reset_n) begin
            counter <= 0;
            ramp_data <= 0;
        end else begin
            if (counter >= DIVISOR - 1) begin
                counter <= 0;
                if (ramp_data >= 8'd255) begin
                    ramp_data <= 0;
                end else begin
                    ramp_data <= ramp_data + 1;
                end
            end else begin
                counter <= counter + 1;
            end
        end
    end

    assign plot_distance = ramp_data;

endmodule