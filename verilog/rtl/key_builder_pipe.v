`define USE_POWER_PINS
`timescale 1ns / 1ps

module key_builder_pipe (
            //frst version, some selected metadta frm parser
    input  [31:0] src_ip,
    input  [31:0] dst_ip,
    input  [7:0]  ip_proto,
    input  [15:0] src_port,
    input  [15:0] dst_port,
    input  [11:0] vlan_id,
    input  [5:0]  dscp,

    input         is_ipv4,
    input         is_ipv6,
    input         is_arp,
    input         is_fragmented,

    
    output [127:0] tcam_key
);

    assign tcam_key = {
        src_ip,   // [127:96]
        dst_ip,        // [95:64]
        ip_proto,     // [63:56]
        src_port,        // [55:40]
        dst_port,        // [39:24]
        vlan_id,         // [23:12]
        dscp,            // [11:6]
        is_ipv4,         // [5]
        is_ipv6,         // [4]
        is_arp,          // [3]
        is_fragmented,   // [2]
        2'b00            // [1:0]
    };

endmodule
