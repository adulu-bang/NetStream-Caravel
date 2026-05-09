import sys

header = """`timescale 1ns / 1ps

module tb_30_cases;

    reg clk;
    reg rst_n;

    // mac side
    reg            rx_valid;
    reg  [7:0]     rx_data;
    reg            rx_last;
    wire           rx_ready;

    wire           tx_valid;
    wire [7:0]     tx_data;
    wire           tx_last;
    wire           tx_ready = 1'b1;

    // control plane
    reg            cfg_tcam_wr_en;
    reg            cfg_tcam_wr_is_mask;
    reg  [4:0]     cfg_tcam_wr_addr;
    reg  [127:0]   cfg_tcam_wr_data;

    reg            cfg_action_wr_en;
    reg  [4:0]     cfg_action_wr_addr;
    reg  [63:0]    cfg_action_wr_data;

    reg            cfg_action_wr_default;
    reg  [63:0]    cfg_action_default_data;

    dataplane_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .rx_valid(rx_valid),
        .rx_data(rx_data),
        .rx_last(rx_last),
        .rx_ready(rx_ready),
        .tx_valid(tx_valid),
        .tx_data(tx_data),
        .tx_last(tx_last),
        .tx_ready(tx_ready),
        .cfg_tcam_wr_en(cfg_tcam_wr_en),
        .cfg_tcam_wr_is_mask(cfg_tcam_wr_is_mask),
        .cfg_tcam_wr_addr(cfg_tcam_wr_addr),
        .cfg_tcam_wr_data(cfg_tcam_wr_data),
        .cfg_action_wr_en(cfg_action_wr_en),
        .cfg_action_wr_addr(cfg_action_wr_addr),
        .cfg_action_wr_data(cfg_action_wr_data),
        .cfg_action_wr_default(cfg_action_wr_default),
        .cfg_action_default_data(cfg_action_default_data)
    );

    always #5 clk = ~clk;

    integer f_out;

    task write_tcam(input [4:0] addr, input [127:0] val, input [127:0] mask);
    begin
        @(posedge clk);
        cfg_tcam_wr_addr = addr;
        cfg_tcam_wr_data = val;
        cfg_tcam_wr_is_mask = 0;
        cfg_tcam_wr_en = 1;
        @(posedge clk);
        cfg_tcam_wr_data = mask;
        cfg_tcam_wr_is_mask = 1;
        @(posedge clk);
        cfg_tcam_wr_en = 0;
    end
    endtask

    task write_action(input [4:0] addr, input [2:0] act_type, input [59:0] act_data);
    begin
        @(posedge clk);
        cfg_action_wr_addr = addr;
        cfg_action_wr_data = {1'b1, act_type, act_data}; // valid=1
        cfg_action_wr_en = 1;
        @(posedge clk);
        cfg_action_wr_en = 0;
    end
    endtask

    task send_byte(input [7:0] b, input last);
    begin
        rx_valid = 1;
        rx_data  = b;
        rx_last  = last;
        while (!(rx_valid && rx_ready)) @(posedge clk);
        @(posedge clk);
        rx_valid = 0;
        rx_last  = 0;
    end
    endtask

    task send_packet(input [7:0] val);
    begin
        send_byte(8'h11, 0); send_byte(8'h22, 0); send_byte(8'h33, 0); send_byte(8'h44, 0); send_byte(8'h55, 0); send_byte(8'h66, 0);
        send_byte(8'hAA, 0); send_byte(8'hBB, 0); send_byte(8'hCC, 0); send_byte(8'hDD, 0); send_byte(8'hEE, 0); send_byte(8'hFF, 0);
        send_byte(8'h08, 0); send_byte(8'h00, 0); // IPv4

        // IPv4 Header (20 bytes)
        send_byte(8'h45, 0); send_byte(val, 0); // DSCP = val
        send_byte(8'h00, 0); send_byte(8'h28, 0);
        send_byte(8'h00, 0); send_byte(8'h00, 0); send_byte(8'h40, 0); send_byte(8'h00, 0);
        send_byte(8'h40, 0); // TTL = 64
        send_byte(8'h06, 0); // TCP
        send_byte(8'h00, 0); send_byte(8'h00, 0);
        send_byte(192, 0); send_byte(168, 0); send_byte(1, 0); send_byte(val, 0); // SRC IP
        send_byte(10, 0); send_byte(0, 0); send_byte(0, 0); send_byte(val, 0); // DST IP

        // TCP Header + payload
        send_byte(8'h12, 0); send_byte(8'h34, 0); // SRC PORT
        send_byte(8'h00, 0); send_byte(val, 0); // DST PORT
        send_byte(8'hDE, 0); send_byte(8'hAD, 0); send_byte(8'hBE, 0); send_byte(8'hEF, 1);
    end
    endtask

    initial begin
        f_out = $fopen("tb_30_out.log", "w");
        clk = 0;
        rst_n = 0;
        rx_valid = 0; rx_data = 0; rx_last = 0;
        cfg_tcam_wr_en = 0; cfg_tcam_wr_is_mask = 0; cfg_tcam_wr_addr = 0; cfg_tcam_wr_data = 0;
        cfg_action_wr_en = 0; cfg_action_wr_addr = 0; cfg_action_wr_data = 0;
        cfg_action_wr_default = 0; cfg_action_default_data = 0;

        #100;
        rst_n = 1;
        #100;

        $display("Hardware Initialization: Zeroing TCAM and Action tables...");
        for (integer idx = 0; idx < 32; idx = idx + 1) begin
            write_tcam(idx, 128'h0, 128'h0);
            write_action(idx, 3'b000, 60'h0);
        end

        // Config 5 rules (Simple variation of DST IP or DSCP matching)
"""

footer = """
        // Default action
        @(posedge clk);
        cfg_action_wr_default = 1;
        cfg_action_default_data = {1'b1, 3'b000, 60'd0}; 
        @(posedge clk);
        cfg_action_wr_default = 0;

        #100;
        $display("Sending 5 Packets...");
"""

run_tests = ""
for i in range(1, 6):
    run_tests += f"        $display(\"--- TEST {i} ---\");\n"
    run_tests += f"        send_packet({i});\n"
    run_tests += f"        #500;\n"

end_footer = """
        #5000;
        $fclose(f_out);
        $display("[SUCCESS] Finished 5 testcases.");
        $finish;
    end

    always @(posedge clk) begin
        if (tx_valid) begin
            $display("DATA: %02h | LAST: %b", tx_data, tx_last);
        end
    end
endmodule
"""

with open("tb_30_cases.v", "w") as f:
    f.write(header)
    for i in range(1, 6):
        # We will write rules to match the DST IP's last byte = i, action = modify destination MAC to 00:11:22:33:44:i
        rule_val = f"128'h0000000000000000000000000A0000{i:02x}"
        rule_mask = "128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        # act_type = 2 (Dest MAC rewrite)
        act_data = f"60'h00000011223344{i:02x}"
        f.write(f"        write_tcam({i-1}, {rule_val}, {rule_mask});\n")
        f.write(f"        write_action({i-1}, 3'b010, {act_data});\n")

    f.write(footer)
    f.write(run_tests)
    f.write(end_footer)

print("tb_5_cases.v generated successfully.")
