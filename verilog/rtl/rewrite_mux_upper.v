`define USE_POWER_PINS
`timescale 1ns / 1ps
module rewrite_mux_upper #(
    parameter ACTION_W = 64
)(
    input  clk,
    input  rst_n,

    // from pkt fifo
    input        in_valid,
    input  [7:0] in_data,
    input        in_last,
    output       in_ready,

    // to mac/nxt stage
    output reg        out_valid,
    output reg [7:0]  out_data,
    output reg        out_last,
    input             out_ready,

    // control
    input             pkt_sop,   
    input  [ACTION_W-1:0] action,

    input  [15:0] l2_offset,
    input  [15:0] l3_offset,
    input  [15:0] l4_offset
);

assign in_ready = out_ready;

//byte index (absolute byte of pkt)
reg [15:0] byte_index;

always @(posedge clk) begin
    if (!rst_n) begin
        byte_index <= 16'd0;
    end else if (pkt_sop /*&& in_valid && in_ready*/) begin
        byte_index <= 16'd0;
    end else if (in_valid && in_ready) begin
        byte_index <= byte_index + 1;
    end
end


//action decode
wire rewrite_en  = action[63];
wire [2:0] rtype = action[62:60];

//datapath (more functionality like dropping and further rewrites to be added)
always @(posedge clk) begin
    if (!rst_n) begin
        out_valid <= 1'b0;
        out_data  <= 8'd0;
        out_last  <= 1'b0;
    end else begin
        out_valid <= in_valid;
        out_last  <= in_last;

        if (in_valid && in_ready) begin
            out_data <= in_data;   

            if (rewrite_en) begin
                case (rtype)

                // L3 example: rewrite IPv4 DSCP (byte l3_offset + 1)
                3'b010: begin
                    if (byte_index == (l3_offset + 16'd1))
                        out_data <= {action[5:0], in_data[1:0]};
                end

                // L2 example: rewrite destination MAC (bytes 0 to 5)
                3'b011: begin
                    if (byte_index < 6)
                        out_data <= action[47 - (byte_index*8) -: 8];
                end

                default: ;
                endcase
            end
        end
    end
end

endmodule
