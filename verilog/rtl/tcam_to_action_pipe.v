`define USE_POWER_PINS
`timescale 1ns / 1ps
module tcam_to_action_pipe (
    input  clk,
    input  rst_n,

    input        tcam_valid,// frm prev pipeline reg (key_valid)
    input        tcam_hit,
    input [3:0]  tcam_hit_index,

    output       tcam_ready,

    output reg        action_valid,
    input             action_ready,
    output reg        action_hit,
    output reg [3:0]  action_index
);

    assign tcam_ready = !action_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            action_valid <= 1'b0;
        end else begin
            if (action_valid && action_ready)
                action_valid <= 1'b0;

            if (tcam_valid && tcam_ready) begin
                action_valid <= 1'b1;
                action_hit   <= tcam_hit;
                action_index <= tcam_hit_index;
            end
        end
    end
endmodule
