`define USE_POWER_PINS
`timescale 1ns / 1ps
module header_to_parser_pipe_reg #(
    parameter HEADER_BYTES = 192,
    parameter PTR_W = 8
)(
    input                          clk,
    input                          rst_n,

    input                          header_valid,//level showin if the header in buffer is valid to come here
    input  [8*HEADER_BYTES-1:0]    header_flat,//buffer
    input  [PTR_W:0]               header_len,// length of pkt (keeps inc till payload over)
    output                         header_ready,// dis gos to header buffer, tellin its ready to accept the header data

    output reg                     hdr_valid,// frm pipeline reg to fsm sayin valid
    output reg [8*HEADER_BYTES-1:0] hdr_flat,//reg
    input                          hdr_ready//frm fsm
);

    assign header_ready = !hdr_valid || hdr_ready;// VV imp .... C1: whn its empty (sy strting), C2: whn fsm is redy for nxt pkt, u dont need to waste 1 extra cycle waitin for hdr_valid go to 0

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hdr_valid <= 0;
            hdr_flat <= {8*HEADER_BYTES{1'b0}};
          //  hdr_len   <= '0;
        end else begin
            if (header_valid && header_ready) begin//shkehnd with header buffer
                hdr_valid <= 1'b1;// make it valid for fsm
                hdr_flat  <= header_flat;// take the header data
            //    hdr_len   <= header_len;//assign the total pkt len 
            end else if (hdr_valid && hdr_ready) begin//shkehand with fsm
                 hdr_valid <= 1'b0;//so tht nxt cycle itself the nxt pkt cn cm in frm hdr buffer
            end
        end
    end
endmodule


