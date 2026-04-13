`define USE_POWER_PINS
`timescale 1ns / 1ps
module action_drain_ctrl_upper #(
    parameter ACTION_W = 64
)(
    input  wire               clk,
    input  wire               rst_n,

    // from action engine
    input  wire               action_valid,
    input  wire [ACTION_W-1:0] action_in,

    // to packet FIFO
    output reg                allow_drain,
    output reg [ACTION_W-1:0] action_out
);

always @(posedge clk) begin
    if (!rst_n) begin
        allow_drain <= 1'b0;
        action_out  <= {ACTION_W{1'b0}};
    end else begin
        // default
        allow_drain <= 1'b0;

        // one pulse = one packet credit
        if (action_valid) begin
            allow_drain <= 1'b1;
            action_out  <= action_in;
        end
    end
end

endmodule

