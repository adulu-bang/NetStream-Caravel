`define USE_POWER_PINS
`timescale 1ns / 1ps

module parser_fsm_pipe_2
#(
    parameter HEADER_BYTES = 192,
    parameter PTR_W = 8
)
(
    input              clk,
    input              rst_n,

    input hdr_valid,// frm pipeline reg
    input [8*HEADER_BYTES-1:0] hdr_flat,//"
    output hdr_ready,//to the prev buffer

    output parser_valid,
    input parser_ready,// frm nxt pipe reg




  //l2
    output reg [47:0]  src_mac,
    output reg [47:0]  dst_mac,
    output reg         has_vlan,
    output reg [11:0]  vlan_id,

//l3
    output reg         is_ipv4,
    output reg         is_ipv6,
    output reg         is_arp,

    output reg [31:0]  src_ip,
    output reg [31:0]  dst_ip,

    output reg [7:0]   ttl,//time to liv
    output reg [5:0]   dscp,//givs priority to packets
    output reg [1:0]   ecn,//tells if packet passed thru a congested queue
    output reg         is_fragmented,//detect frgments

   //l4
    output reg [7:0]   ip_proto,
    output reg [15:0]  src_port,
    output reg [15:0]  dst_port,
    output reg [7:0]   tcp_flags,
    output reg [7:0]   icmp_type,

    // packet control
    output reg        pkt_start,
    output reg        pkt_end,

    // lengths / offsets
    output reg [15:0] l2_offset,   // usually 0, but explicit is good
    output reg [15:0] l3_offset,
    output reg [15:0] l4_offset,
    output reg [7:0]  ip_hdr_len,  // bytes
    output reg [15:0] header_len // end of L4 header


    );

    `define HB(i) hdr_flat[(i)*8 +: 8]


    
    localparam S_IDLE        = 4'd0;
    localparam S_WAIT        = 4'd1;
    localparam S_ETH         = 4'd2;
    localparam S_VLAN        = 4'd3;

    localparam S_IPV4_1      = 4'd4; 
    localparam S_IPV4_2      = 4'd5; 
    localparam S_IPV4_3      = 4'd6; 
    localparam S_IPV4_4      = 4'd7; 
    localparam S_IPV4_5      = 4'd8; 

    localparam S_IPV6        = 4'd9;
    localparam S_L4          = 4'd10;
    localparam S_DONE        = 4'd11;

    reg [3:0]  state;
    reg [15:0] ethertype;
    reg [7:0]  byte_tmp;

  
    assign parser_valid = (state == S_DONE);


    assign hdr_ready = (state == S_IDLE) && parser_ready;//*check!!!!


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= S_IDLE;

             has_vlan       <= 1'b0;
            vlan_id        <= 12'd0;
            is_ipv4        <= 1'b0;
            is_ipv6        <= 1'b0;
            is_arp         <= 1'b0;
            is_fragmented  <= 1'b0;
            src_ip         <= 32'd0;
            dst_ip         <= 32'd0;
            src_port       <= 16'd0;
            dst_port       <= 16'd0;
            tcp_flags      <= 8'd0;
            icmp_type      <= 8'd0;
            
            pkt_start <= 1'b0;
            pkt_end   <= 1'b0;
        end else begin
            pkt_start <= 1'b0;
            pkt_end   <= 1'b0;


            case (state)

   
            S_IDLE: begin
                if (hdr_valid && hdr_ready)begin
                    pkt_start <= 1'b1;
                    l2_offset <= 16'd0;
                    header_len <= 16'd0; // will be computed later
                    state <= S_ETH;
                end
            end


        
           // S_WAIT:

            S_ETH: begin
                dst_mac   <= {`HB(0),`HB(1),`HB(2),`HB(3),`HB(4),`HB(5)};
                src_mac   <= {`HB(6),`HB(7),`HB(8),`HB(9),`HB(10),`HB(11)};
                ethertype <= {`HB(12),`HB(13)};

                if ({`HB(12),`HB(13)} == 16'h8100) begin
                    has_vlan <= 1'b1;
                    l3_offset <= 16'd18;
                    state    <= S_VLAN;
                end else begin
                    has_vlan <= 1'b0;
                    l3_offset <= 16'd14;
                    state    <= S_IPV4_1;
                end
            end

            
            S_VLAN: begin
                byte_tmp  <= `HB(14);
                vlan_id   <= {byte_tmp[3:0], `HB(15)};
                ethertype <= {`HB(16),`HB(17)};
                state     <= S_IPV4_1;
            end

            
            S_IPV4_1: begin
                is_ipv4 <= (ethertype == 16'h0800);
                is_arp  <= (ethertype == 16'h0806);
                is_ipv6 <= (ethertype == 16'h86DD);

                if (ethertype == 16'h0806)
                    state <= S_DONE;
                else if (ethertype == 16'h0800) begin
                    byte_tmp <= `HB(l3_offset + 1);
                    state    <= S_IPV4_2;
                end
                else if (ethertype == 16'h86DD)
                    state <= S_IPV6;
                else
                    state <= S_DONE;
            end

            S_IPV4_2: begin
                dscp <= byte_tmp[7:2];
                ecn  <= byte_tmp[1:0];
                ttl  <= `HB(l3_offset + 8);
                ip_proto <= `HB(l3_offset + 9);
                byte_tmp <= `HB(l3_offset + 6);
                state <= S_IPV4_3;
            end

            S_IPV4_3: begin
                is_fragmented <=
                    (byte_tmp[5] == 1'b1) ||
                    ({byte_tmp[4:0], `HB(l3_offset + 7)} != 13'd0);
                state <= S_IPV4_4;
            end

            S_IPV4_4: begin
                src_ip <= {`HB(l3_offset+12),`HB(l3_offset+13),
                           `HB(l3_offset+14),`HB(l3_offset+15)};
                dst_ip <= {`HB(l3_offset+16),`HB(l3_offset+17),
                           `HB(l3_offset+18),`HB(l3_offset+19)};
                byte_tmp <= `HB(l3_offset); // IHL
                state <= S_IPV4_5;
            end

            S_IPV4_5: begin
                ip_hdr_len <= (byte_tmp[3:0] << 2);   // IHL * 4
                l4_offset <= l3_offset + (byte_tmp[3:0] << 2);
                state <= S_L4;
            end

           
            S_IPV6: begin// not fully, didnt handle extention headrs for noww
                ip_proto  <= `HB(l3_offset + 6);
                ip_hdr_len <= 8'd40;
                l4_offset <= l3_offset + 16'd40;
                state <= S_L4;
            end

            
            S_L4: begin
                if (ip_proto == 8'd6) begin//tcp
                    src_port  <= {`HB(l4_offset),`HB(l4_offset+1)};
                    dst_port  <= {`HB(l4_offset+2),`HB(l4_offset+3)};
                    tcp_flags <= `HB(l4_offset + 13);
                    header_len <= l4_offset + 16'd20;
                end
                else if (ip_proto == 8'd17) begin//udp
                    src_port <= {`HB(l4_offset),`HB(l4_offset+1)};
                    dst_port <= {`HB(l4_offset+2),`HB(l4_offset+3)};
                    header_len <= l4_offset + 16'd8;
                end
                else if (ip_proto == 8'd1 || ip_proto == 8'd58) begin
                    icmp_type <= `HB(l4_offset);
                    header_len <= l4_offset;
                end
                state <= S_DONE;
            end

            S_DONE: begin
                pkt_end <= 1'b1;
                if (parser_ready) begin
                    pkt_end <= 1'b0;
                    state <= S_IDLE;
                end
            end

            default:
                state <= S_IDLE;
            endcase
        end
    end

endmodule
