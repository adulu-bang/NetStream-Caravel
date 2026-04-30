module dataplane_top (cfg_action_wr_default,
    cfg_action_wr_en,
    cfg_tcam_wr_en,
    cfg_tcam_wr_is_mask,
    clk,
    rst_n,
    rx_last,
    rx_ready,
    rx_valid,
    tx_last,
    tx_ready,
    tx_valid,
    vccd1,
    vssd1,
    cfg_action_default_data,
    cfg_action_wr_addr,
    cfg_action_wr_data,
    cfg_tcam_wr_addr,
    cfg_tcam_wr_data,
    rx_data,
    tx_data);
 input cfg_action_wr_default;
 input cfg_action_wr_en;
 input cfg_tcam_wr_en;
 input cfg_tcam_wr_is_mask;
 input clk;
 input rst_n;
 input rx_last;
 output rx_ready;
 input rx_valid;
 output tx_last;
 input tx_ready;
 output tx_valid;
 inout vccd1;
 inout vssd1;
 input [63:0] cfg_action_default_data;
 input [4:0] cfg_action_wr_addr;
 input [63:0] cfg_action_wr_data;
 input [4:0] cfg_tcam_wr_addr;
 input [127:0] cfg_tcam_wr_data;
 input [7:0] rx_data;
 output [7:0] tx_data;

endmodule
