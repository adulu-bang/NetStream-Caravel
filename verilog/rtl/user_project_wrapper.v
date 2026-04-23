// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_project_wrapper
 *
 * This wrapper enumerates all of the pins available to the
 * user for the user project.
 *
 * An example user project is provided in this wrapper.  The
 * example should be removed and replaced with the actual
 * user project.
 *
 *-------------------------------------------------------------
 */
`define USE_POWER_PINS
module user_project_wrapper #(
    parameter BITS = 32
) (
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // Analog (direct connection to GPIO pad---use with caution)
    // Note that analog I/O is not available on the 7 lowest-numbered
    // GPIO pads, and so the analog_io indexing is offset from the
    // GPIO indexing by 7 (also upper 2 GPIOs do not have analog_io).
    inout [`MPRJ_IO_PADS-10:0] analog_io,

    // Independent clock (on independent integer divider)
    input   user_clock2,

    // User maskable interrupt signals
    output [2:0] user_irq
);


wire clk = wb_clk_i;
wire rst_n = ~wb_rst_i;

// ---------------- GPIO MAPPING ----------------

// RX (inputs)
wire        rx_valid = io_in[0];
wire [7:0]  rx_data  = io_in[8:1];
wire        rx_last  = io_in[9];

// TX control input
wire tx_ready = io_in[10];

// TX (outputs)
wire        tx_valid;
wire [7:0]  tx_data;
wire        tx_last;

// RX ready output
wire rx_ready;

// Assign outputs
assign io_out[11]    = tx_valid;
assign io_out[19:12] = tx_data;
assign io_out[20]    = tx_last;
assign io_out[21]    = rx_ready;

// ---------------- GPIO DIRECTION ----------------

// Inputs
assign io_oeb[0]  = 1; // rx_valid
assign io_oeb[8:1] = 1; // rx_data
assign io_oeb[9]  = 1; // rx_last
assign io_oeb[10] = 1; // tx_ready

// Outputs
assign io_oeb[11]    = 0; // tx_valid
assign io_oeb[19:12] = 0; // tx_data
assign io_oeb[20]    = 0; // tx_last
assign io_oeb[21]    = 0; // rx_ready

// Rest unused → inputs
assign io_oeb[`MPRJ_IO_PADS-1:22] = {(`MPRJ_IO_PADS-22){1'b1}};
assign io_out[`MPRJ_IO_PADS-1:22] = 0;

// ---------------- WISHBONE DECODER ----------------

    // Wishbone active flags
    wire wb_valid = wbs_cyc_i & wbs_stb_i;
    wire wb_write = wb_valid & wbs_we_i;

    // Payloads
    reg [31:0] tcam_payload_0, tcam_payload_1, tcam_payload_2, tcam_payload_3;
    reg [31:0] action_payload_0, action_payload_1;

    wire [127:0] tcam_data_out = {tcam_payload_3, tcam_payload_2, tcam_payload_1, tcam_payload_0};
    wire [63:0]  action_data_out = {action_payload_1, action_payload_0};

    // Control registers
    reg cfg_tcam_wr_en;
    reg cfg_tcam_wr_is_mask;
    reg [4:0] cfg_tcam_wr_addr;

    reg cfg_action_wr_en;
    reg [4:0] cfg_action_wr_addr;
    reg cfg_action_wr_default;

    reg wbs_ack;
    assign wbs_ack_o = wbs_ack;


    always @(posedge wb_clk_i) begin
        if (wb_rst_i) begin
            wbs_ack <= 0;
            cfg_tcam_wr_en <= 0;
            cfg_action_wr_en <= 0;
            cfg_action_wr_default <= 0;
        end else begin
            cfg_tcam_wr_en <= 0;
            cfg_action_wr_en <= 0;
            cfg_action_wr_default <= 0;

            if (wb_valid && !wbs_ack) begin
                wbs_ack <= 1;
                
                if (wb_write) begin
                    case (wbs_adr_i[7:0])

                        // TCAM Payloads
                        8'h00: tcam_payload_0 <= wbs_dat_i;
                        8'h04: tcam_payload_1 <= wbs_dat_i;
                        8'h08: tcam_payload_2 <= wbs_dat_i;
                        8'h0C: tcam_payload_3 <= wbs_dat_i;

                        8'h10: begin // VALUE write
                            cfg_tcam_wr_addr <= wbs_dat_i[4:0];
                            cfg_tcam_wr_is_mask <= 0;
                            cfg_tcam_wr_en <= 1;              
                        end
                        8'h14: begin // MASK write
                            cfg_tcam_wr_addr <= wbs_dat_i[4:0];
                            cfg_tcam_wr_is_mask <= 1;
                            cfg_tcam_wr_en <= 1;
                        end

                        // ACTION Payloads
                        8'h20: action_payload_0 <= wbs_dat_i;
                        8'h24: action_payload_1 <= wbs_dat_i;

                        8'h28: begin // ACTION write
                            cfg_action_wr_addr <= wbs_dat_i[4:0];
                            cfg_action_wr_en <= 1;
                        end
                        8'h2C: begin // DEFAULT ACTION write
                            cfg_action_wr_default <= 1;
                        end
                    endcase
                end
            end else begin
                wbs_ack <= 0; 
            end
        end
    end

dataplane_top u_dataplane (
    `ifdef USE_POWER_PINS
 	.vccd1(vccd1),	// User area 1 1.8V power
 	.vssd1(vssd1),	// User area 1 digital ground
    `endif

    .clk(clk),
    .rst_n(rst_n),

    .rx_valid(rx_valid),
    .rx_data(rx_data),
    .rx_last(rx_last),
    .rx_ready(rx_ready),   // ignore for now or map to io

    .tx_valid(tx_valid),
    .tx_data(tx_data),
    .tx_last(tx_last),
    .tx_ready(tx_ready),

    .cfg_tcam_wr_en(cfg_tcam_wr_en),
    .cfg_tcam_wr_is_mask(cfg_tcam_wr_is_mask),
    .cfg_tcam_wr_addr(cfg_tcam_wr_addr),
    .cfg_tcam_wr_data(tcam_data_out),

    .cfg_action_wr_en(cfg_action_wr_en),
    .cfg_action_wr_addr(cfg_action_wr_addr),
    .cfg_action_wr_data(action_data_out),
    .cfg_action_wr_default(cfg_action_wr_default),
    .cfg_action_default_data(action_data_out)
);

assign wbs_dat_o = 0;
assign la_data_out = 0;
assign user_irq = 0;














/*--------------------------------------*/
/* User project is instantiated  here   */
/*--------------------------------------*/

// user_proj_example mprj (
// `ifdef USE_POWER_PINS
// 	.vccd1(vccd1),	// User area 1 1.8V power
// 	.vssd1(vssd1),	// User area 1 digital ground
// `endif

//     .wb_clk_i(wb_clk_i),
//     .wb_rst_i(wb_rst_i),

//     // MGMT SoC Wishbone Slave

//     .wbs_cyc_i(wbs_cyc_i),
//     .wbs_stb_i(wbs_stb_i),
//     .wbs_we_i(wbs_we_i),
//     .wbs_sel_i(wbs_sel_i),
//     .wbs_adr_i(wbs_adr_i),
//     .wbs_dat_i(wbs_dat_i),
//     .wbs_ack_o(wbs_ack_o),
//     .wbs_dat_o(wbs_dat_o),

//     // Logic Analyzer

//     .la_data_in(la_data_in),
//     .la_data_out(la_data_out),
//     .la_oenb (la_oenb),

//     // IO Pads

//     .io_in ({io_in[37:30],io_in[7:0]}),
//     .io_out({io_out[37:30],io_out[7:0]}),
//     .io_oeb({io_oeb[37:30],io_oeb[7:0]}),

//     // IRQ
//     .irq(user_irq)
// );




endmodule	// user_project_wrapper

`default_nettype wire




// wire [7:0] count;

// wire clk_int = wb_clk_i;
// wire rst_int = wb_rst_i;

// counter u_counter (
// `ifdef USE_POWER_PINS
//     .VPWR(vccd1),
//     .VGND(vssd1),
// `endif
//     .clk(clk_int),
//     .rst(rst_int),
//     .count(count)
// );

// assign io_out[7:0] = count;
// assign io_oeb[7:0] = 8'b0;   // output enabled

// // rest unused
// assign io_out[37:8] = 0;
// assign io_oeb[37:8] = 1;     // input (disabled output)

// assign wbs_ack_o = 0;
// assign wbs_dat_o = 0;

// assign la_data_out = 0;
// assign user_irq = 3'b000;

