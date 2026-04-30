`timescale 1ns/1ps

module tb_dataplane_top_real;
localparam HEADER_BYTES = 192;


integer k;

wire [7:0] header_bytes [0:HEADER_BYTES-1];

genvar i;
generate
  for (i = 0; i < HEADER_BYTES; i = i + 1) begin : GEN_HDR
    assign header_bytes[i] =
        dut.header_flat[(i*8) +: 8];
  end
endgenerate


initial begin
    
    $dumpfile("dataplane.vcd");
    $dumpvars(0, tb_dataplane_top_real);

    $dumpvars(0, tx_valid);
    $dumpvars(0, tx_data);
    $dumpvars(0, tx_last);

   for (k = 0; k < 512; k = k + 1) begin
        $dumpvars(0, tb_dataplane_top_real.dut.u_packet_fifo_upper.mem_last[k]);
        $dumpvars(0, tb_dataplane_top_real.dut.u_packet_fifo_upper.mem[k]);
    end



end


    reg clk;
    reg rst_n;

    //simulate the mac here
    reg        rx_valid;
    reg [7:0]  rx_data;
    reg        rx_last;
    wire       rx_ready;

    // TCAM control
    reg        tcam_wr_en;
    reg        tcam_wr_is_mask;
    reg [4:0]  tcam_wr_addr;
    reg [127:0] tcam_wr_data;

    // Action control
    reg        action_wr_en;
    reg [4:0]  action_wr_addr;
    reg [63:0] action_wr_data;
    reg        action_wr_default;
    reg [63:0] action_default_data;

    wire        tx_valid;
    wire [7:0]  tx_data;
    wire        tx_last;

    // DUT
    dataplane_top dut (
    .clk      (clk),
    .rst_n    (rst_n),

    .rx_valid (rx_valid),
    .rx_data  (rx_data),
    .rx_last  (rx_last),
    .rx_ready (rx_ready),

    .tx_valid (tx_valid),   // ignore for now
    .tx_data  (tx_data),
    .tx_last  (tx_last),
    .tx_ready (1'b1), // always ready for first sim

    .cfg_tcam_wr_en        (tcam_wr_en),
    .cfg_tcam_wr_is_mask  (tcam_wr_is_mask),
    .cfg_tcam_wr_addr     (tcam_wr_addr),
    .cfg_tcam_wr_data     (tcam_wr_data),

    .cfg_action_wr_en     (action_wr_en),
    .cfg_action_wr_addr  (action_wr_addr),
    .cfg_action_wr_data  (action_wr_data),
    .cfg_action_wr_default(action_wr_default),
    .cfg_action_default_data(action_default_data)
);


    // Clock: 250 MHz
    initial begin
        clk = 0;
        forever #2 clk = ~clk;
    end

    // Reset
    initial begin
        rst_n = 0;
        rx_valid = 0;
        rx_data  = 0;
        rx_last  = 0;

        tcam_wr_en = 0;
        action_wr_en = 0;
        action_wr_default = 0;

        #40;
        rst_n = 1;
    end




    // ctrl plane tasks


    task tcam_write_value;
        input [4:0] idx;
        input [127:0] value;
        begin
            @(posedge clk);
            tcam_wr_en = 1;
            tcam_wr_is_mask = 0;
            tcam_wr_addr = idx;
            tcam_wr_data = value;
            @(posedge clk);
            tcam_wr_en = 0;
        end
    endtask

    task tcam_write_mask;
        input [4:0] idx;
        input [127:0] mask;
        begin
            @(posedge clk);
            tcam_wr_en = 1;
            tcam_wr_is_mask = 1;
            tcam_wr_addr = idx;
            tcam_wr_data = mask;
            @(posedge clk);
            tcam_wr_en = 0;
        end
    endtask

    task action_write;
        input [4:0] idx;
        input [63:0] act;
        begin
            @(posedge clk);
            action_wr_en = 1;
            action_wr_addr = idx;
            action_wr_data = act;
            @(posedge clk);
            action_wr_en = 0;
        end
    endtask

    task action_write_default;
        input [63:0] act;
        begin
            @(posedge clk);
            action_wr_default = 1;
            action_default_data = act;
            @(posedge clk);
            action_wr_default = 0;
        end
    endtask

    task send_byte;
    input [7:0] b;
    input last;
    
    begin
        rx_valid = 1;
        rx_data  = b;
        rx_last  = last;

        // HOLD until accepted
        while (!(rx_valid && rx_ready))
            @(posedge clk);

        @(posedge clk); // complete handshake
        rx_valid = 0;
        rx_last  = 0;
    end
endtask



    task send_ipv4_tcp_short;
    integer i;
    begin
        // ---------------- Ethernet ----------------
         send_byte(8'hFF, 0);
        // dst MAC
       

        send_byte(8'hDA, 0);
        send_byte(8'h02, 0);
        send_byte(8'h03, 0);
        send_byte(8'h04, 0);
        send_byte(8'h05, 0);
        send_byte(8'h06, 0);

        // src MAC
        send_byte(8'hAA, 0);
        send_byte(8'hBB, 0);
        send_byte(8'hCC, 0);
        send_byte(8'hDD, 0);
        send_byte(8'hEE, 0);
        send_byte(8'hFF, 0);

        // Ethertype = IPv4
        send_byte(8'h08, 0);
        send_byte(8'h00, 0);

        // ---------------- IPv4 ----------------
        send_byte(8'h45, 0); // Version=4, IHL=5
        send_byte(8'h00, 0); // DSCP/ECN
        send_byte(8'h00, 0); send_byte(8'h3C, 0); // total length
        send_byte(8'h00, 0); send_byte(8'h00, 0); // ID
        send_byte(8'h40, 0); send_byte(8'h00, 0); // flags/frag
        send_byte(8'h40, 0); // TTL
        send_byte(8'h06, 0); // **TCP**
        send_byte(8'h00, 0); send_byte(8'h00, 0); // checksum

        // src IP = 192.168.1.1
        send_byte(8'hC0, 0); send_byte(8'hA8, 0);
        send_byte(8'h01, 0); send_byte(8'h01, 0);

        // dst IP = 10.0.0.1
        send_byte(8'h0A, 0); send_byte(8'h00, 0);
        send_byte(8'h00, 0); send_byte(8'h01, 0);

        // ---------------- TCP ----------------
        send_byte(8'h04, 0); send_byte(8'hD2, 0); // src port = 1234
        send_byte(8'h00, 0); send_byte(8'h50, 0); // dst port = 80
        for (i = 0; i < 16; i = i + 1)
            send_byte(8'h00, 0);

        // ---------------- Payload ----------------
        for (i = 0; i < 9; i = i + 1)
            send_byte(8'hAA, 0);

        send_byte(8'hAA, 1); // last
    end
endtask


    task send_ipv4_udp_long;
        integer i;
        begin
        send_byte(8'h00, 0);

            // Ethernet
            for (i = 0; i < 12; i = i + 1)
                send_byte(8'h11 + i, 0);
            send_byte(8'h08, 0); send_byte(8'h00, 0);

            // IPv4
            send_byte(8'h45, 0);
            send_byte(8'h00, 0);
            send_byte(8'h01, 0); send_byte(8'h2C, 0); // length > 192
            send_byte(8'h00, 0); send_byte(8'h00, 0);
            send_byte(8'h00, 0); send_byte(8'h00, 0);
            send_byte(8'h40, 0);
            send_byte(8'h11, 0); // **UDP**
            send_byte(8'h00, 0); send_byte(8'h00, 0);

            // src/dst IP
            for (i = 0; i < 8; i = i + 1)
                send_byte(8'h01 + i, 0);

            // UDP header
            send_byte(8'h13, 0); send_byte(8'h88, 0);
            send_byte(8'h00, 0); send_byte(8'h35, 0);
            send_byte(8'h01, 0); send_byte(8'h00, 0);
            send_byte(8'h00, 0); send_byte(8'h00, 0);

            // Payload
            for (i = 0; i < 250; i = i + 1)
                send_byte(i[7:0], (i == 249));
        end
    endtask


    task send_back_to_back;
    begin
        send_ipv4_tcp_short;
        send_ipv4_udp_long;
        send_ipv4_tcp_short;
    end
    endtask







    //test seq
    initial begin
        @(posedge rst_n);
        #20;

    // Match TCP
    tcam_write_value(0, 128'h00000000_00000000_06_0000_0050_000_020);
    tcam_write_mask (0, 128'hFFFFFFFF_FFFFFFFF_00_FFFF_0000_FFF_FFF);

#50
    // Match UDP
    tcam_write_value(1, 128'h00000000_00000000_11_0000_0000_000_020);
    tcam_write_mask (1, 128'hFFFFFFFF_FFFFFFFF_00_FFFF_FFFF_000_000);

    action_write(0, 64'hAAAA_AAAA_AAAA_AAAA);
#50
    action_write(1, 64'hBBBB_BBBB_BBBB_BBBB);
#50
    action_write_default(64'hDEAD_DEAD_DEAD_DEAD);

     #200;

       
        $display("Short IPv4 TCP");
        //send_packet(64, 8'h10);
        send_ipv4_tcp_short;

        #7;
        $display("Long packet >192 bytes");
       // send_packet(300, 8'h40);
        send_ipv4_udp_long;

        #7;
        $display("Long packet >192 bytes");
       // send_packet(300, 8'h40);
        send_ipv4_udp_long;

        #7;
        $display("Short IPv4 TCP");
        //send_packet(64, 8'h10);
        send_ipv4_tcp_short;

         #7;
        $display("Long packet >192 bytes");
       // send_packet(300, 8'h40);
        send_ipv4_udp_long;

         #7;
        $display("Long packet >192 bytes");
       // send_packet(300, 8'h40);
        send_ipv4_udp_long;

         #7;
        $display("Short IPv4 TCP");
        //send_packet(64, 8'h10);
        send_ipv4_tcp_short;
 #7;
        $display("Long packet >192 bytes");
       // send_packet(300, 8'h40);
        send_ipv4_udp_long;

         #7;
        $display("Short IPv4 TCP");
        //send_packet(64, 8'h10);
        send_ipv4_tcp_short;
 #7;
        $display("Long packet >192 bytes");
       // send_packet(300, 8'h40);
        send_ipv4_udp_long;
 #7;
        $display("Long packet >192 bytes");
       // send_packet(300, 8'h40);
        send_ipv4_udp_long;

         #7;
        $display("Short IPv4 TCP");
        //send_packet(64, 8'h10);
        send_ipv4_tcp_short;
 #7;
        $display("Long packet >192 bytes");
       // send_packet(300, 8'h40);
        send_ipv4_udp_long;

         #7;
        $display("Short IPv4 TCP");
        //send_packet(64, 8'h10);
        send_ipv4_tcp_short;







    

        #5000;
        $display("DONE");
        $finish;
    end

endmodule