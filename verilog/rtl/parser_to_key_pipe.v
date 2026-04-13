`define USE_POWER_PINS
`timescale 1ns / 1ps
module parser_to_key_pipe (
    input  clk,
    input  rst_n,


    input        parser_valid,//frm parse fsm
    output       parser_ready,//dis pipeline reg is ready

    input [31:0] src_ip,
    input [31:0] dst_ip,
    input [7:0]  ip_proto,
    input [15:0] src_port,
    input [15:0] dst_port,
    input [11:0] vlan_id,
    input [5:0]  dscp,
    input        is_ipv4,
    input        is_ipv6,
    input        is_arp,
    input        is_fragmented,

    // To key builder/tcam
    output reg        key_valid,// tells tht the metdata stored in its reg is valid (basically metadata IS stored in its reg)
    input             key_ready,// frm downstream

    

    output reg [31:0] key_src_ip,
    output reg [31:0] key_dst_ip,
    output reg [7:0]  key_ip_proto,
    output reg [15:0] key_src_port,
    output reg [15:0] key_dst_port,
    output reg [11:0] key_vlan_id,
    output reg [5:0]  key_dscp,
    output reg        key_is_ipv4,
    output reg        key_is_ipv6,
    output reg        key_is_arp,
    output reg        key_is_fragmented
);

    assign parser_ready = !key_valid;// ready signal to fsm if the metadata here has been given forward

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_valid <= 1'b0;
        end else begin
            // consume
            if (key_valid && key_ready)// imp.... whn metadata stored here has been consumed by further stage
                key_valid <= 1'b0;

            // Capture new parsed packet
            if (parser_valid && parser_ready) begin
                key_valid         <= 1'b1;
                key_src_ip        <= src_ip;
                key_dst_ip        <= dst_ip;
                key_ip_proto      <= ip_proto;
                key_src_port      <= src_port;
                key_dst_port      <= dst_port;
                key_vlan_id       <= vlan_id;
                key_dscp           <= dscp;
                key_is_ipv4       <= is_ipv4;
                key_is_ipv6       <= is_ipv6;
                key_is_arp        <= is_arp;
                key_is_fragmented <= is_fragmented;
            end
        end
    end
endmodule
