// `timescale 1ns / 1ps
// module action_pipe #(
//     parameter ENTRIES  = 16,
//     parameter ACTION_W = 64
// )(
//     input                       clk,
//     input                       rst_n,

//     //frm tcam
//     input                       tcam_valid,
//     input                       hit,
//     input  [$clog2(ENTRIES)-1:0] hit_index,

//     // To forwarding / drop logic
//     output reg                  action_valid,
//     output reg [ACTION_W-1:0]   action,

//     // ctrl plane writes
//     input                       wr_en,
//     input  [$clog2(ENTRIES)-1:0] wr_addr,
//     input  [ACTION_W-1:0]       wr_data,

//     input                       wr_default,
//     input  [ACTION_W-1:0]       default_data
// );

//     reg [ACTION_W-1:0] mem [0:ENTRIES-1];
//     reg [ACTION_W-1:0] default_action;

//     // ctrl plane
//     always @(posedge clk) begin
//         if (wr_en)
//             mem[wr_addr] <= wr_data;
//         if (wr_default)
//             default_action <= default_data;
//     end

//     // dataplane
//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             action_valid <= 1'b0;
//         end else begin
//             action_valid <= tcam_valid;

//             if (tcam_valid) begin
//                 if (hit)
//                     action <= mem[hit_index];
//                 else
//                     action <= default_action;
//             end
//         end
//     end
// endmodule



















// `define USE_POWER_PINS
// module action_pipe #(
//     parameter ENTRIES  = 32,
//     parameter ACTION_W = 64
// )(
//     inout vccd1,
//     inout vssd1,

//     input clk,
//     input rst_n,

//     input tcam_valid,
//     input hit,
//     input [$clog2(ENTRIES)-1:0] hit_index,

//     output reg action_valid,
//     output reg [ACTION_W-1:0] action,

//     input wr_en,
//     input [$clog2(ENTRIES)-1:0] wr_addr,
//     input [ACTION_W-1:0] wr_data,

//     input wr_default,
//     input [ACTION_W-1:0] default_data
// );


// wire [32:0] act_out [0:1];


// genvar i;
// generate
//     for (i = 0; i < 2; i = i + 1) begin : ACTION_MEM

//         sram_32x32 action_mem (
//             `ifdef USE_POWER_PINS
//     .vccd1(vccd1),
//     .vssd1(vssd1),
// `endif
//     .clk0(clk),
//       .csb0(1'b0),
//     .addr0({1'b0, (wr_en ? wr_addr : hit_index)}),
//     .din0({1'b0, wr_data[32*i +: 32]}),
//     .spare_wen0(1'b0),
//     .dout0(act_out[i]),
//     .web0(~(wr_en))
// );

//     end
// endgenerate


// reg [63:0] action_r;

// always @(posedge clk) begin
//     action_r <= {act_out[1][31:0], act_out[0][31:0]};
// end

// reg [63:0] default_action;



// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         default_action<=64'b0;
//         action_valid <= 0;
//         action<=0; end
//     // else if (wr_default)
//     // default_action<= default_data;
//     else begin
//         if (wr_default)
//         default_action<=default_data;

//         action_valid <= tcam_valid;

//         if (tcam_valid) begin
//             if (hit)
//                 action <= action_r;
//             else
//                 action <= default_action;
//         end
//     end
// end

// endmodule























// `define USE_POWER_PINS
// module action_pipe #(
//     parameter ENTRIES  = 32,
//     parameter ACTION_W = 64
// )(
//     inout vccd1,
//     inout vssd1,

//     input clk,
//     input rst_n,

//     input tcam_valid,
//     input hit,
//     input [$clog2(ENTRIES)-1:0] hit_index,

//     output reg action_valid,
//     output reg [ACTION_W-1:0] action,

//     input wr_en,
//     input [$clog2(ENTRIES)-1:0] wr_addr,
//     input [ACTION_W-1:0] wr_data,

//     input wr_default,
//     input [ACTION_W-1:0] default_data
// );


// wire [255:0] act_out;

// sky130_sram_1kbyte_1rw1r_32x256_8 action_mem (
// `ifdef USE_POWER_PINS
//     .vccd1(vccd1),
//     .vssd1(vssd1),
// `endif

//     .clk0(clk),
//     .csb0(1'b0),
//     .web0(~wr_en),

//     .addr0(wr_en ? wr_addr : hit_index),
//     .din0({192'b0, wr_data}),  
//     .dout0(act_out),

//     .wmask0(4'b1111),

   
//     .clk1(clk),
//     .csb1(1'b1),
//     .addr1(0),
//     .dout1()
// );


// reg [63:0] action_r;

// always @(posedge clk) begin
//     action_r <= act_out[63:0];
// end


// reg [63:0] default_action;


// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         default_action <= 64'b0;
//         action_valid   <= 0;
//         action         <= 0;
//     end else begin

//         if (wr_default)
//             default_action <= default_data;

//         action_valid <= tcam_valid;

//         if (tcam_valid) begin
//             if (hit)
//                 action <= action_r;
//             else
//                 action <= default_action;
//         end
//     end
// end

// endmodule

























`define USE_POWER_PINS
module action_pipe #(
    parameter ENTRIES  = 32,   // FIXED to match macro
    parameter ACTION_W = 64
)(
    inout vccd1,
    inout vssd1,

    input clk,
    input rst_n,

    input tcam_valid,
    input hit,
    input [$clog2(ENTRIES)-1:0] hit_index,

    output reg action_valid,
    output reg [ACTION_W-1:0] action,

    input wr_en,
    input [$clog2(ENTRIES)-1:0] wr_addr,
    input [ACTION_W-1:0] wr_data,

    input wr_default,
    input [ACTION_W-1:0] default_data
);

wire [31:0] act_out [0:1];

wire [$clog2(ENTRIES)-1:0] addr_mux;
assign addr_mux = wr_en ? wr_addr : hit_index;

genvar i;
generate
    for (i = 0; i < 2; i = i + 1) begin : ACTION_MEM

        RAM32 action_mem (
            .CLK  (clk),
            .EN0  (1'b1),

`ifdef USE_POWER_PINS
            .VPWR (vccd1),
            .VGND (vssd1),
`endif

            // Address mux: write OR read
            .A0 (addr_mux[4:0]),

            // Data input
            .Di0  (wr_data[32*i +: 32]),

            // Output
            .Do0  (act_out[i]),

            // Write enable
            .WE0  (wr_en ? 4'b1111 : 4'b0000)
        );

    end
endgenerate
 
reg [63:0] action_r;

always @(posedge clk) begin
    action_r <= {act_out[1], act_out[0]};
end

reg [63:0] default_action;

reg action_valid_d;
initial begin
    action_valid_d = 0;
end
always @(posedge clk) begin
    action_valid_d <= action_valid;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        default_action <= 64'b0;
        action_valid <= 0;
        action <= 0;
    end else begin
        if (wr_default)
            default_action <= default_data;

        action_valid <= tcam_valid;

        if (action_valid_d) begin
            if (hit)
                action <= action_r;
            else
                action <= default_action;
        end
    end
end

endmodule
























//---------------------------------------------------------------






// `define USE_POWER_PINS
// module action_pipe #(
//     parameter ENTRIES  = 64,    // MUST match SRAM (64)
//     parameter ACTION_W = 64
// )(
//     inout vccd1,
//     inout vssd1,

//     input clk,
//     input rst_n,

//     input tcam_valid,
//     input hit,
//     input [$clog2(ENTRIES)-1:0] hit_index,

//     output reg action_valid,
//     output reg [ACTION_W-1:0] action,

//     input wr_en,
//     input [$clog2(ENTRIES)-1:0] wr_addr,
//     input [ACTION_W-1:0] wr_data,

//     input wr_default,
//     input [ACTION_W-1:0] default_data
// );

// wire [31:0] act_out [0:1];

// genvar i;
// generate
//     for (i = 0; i < 2; i = i + 1) begin : ACTION_MEM

//         sram22_64x32m4w8 action_mem (
// `ifdef USE_POWER_PINS
//             .vdd(vccd1),
//             .vss(vssd1),
// `endif
//             .clk(clk),
//             .rstb(rst_n),

//             .ce(1'b1),

//             // write enable
//             .we(wr_en),

//             // full 32-bit write
//             .wmask(4'b1111),

//             // address mux (IMPORTANT)
//             .addr(wr_en ? wr_addr[5:0] : hit_index[5:0]),

//             .din(wr_data[32*i +: 32]),

//             .dout(act_out[i])
//         );

//     end
// endgenerate

// // combine 2 SRAM outputs (1-cycle latency already handled)
// reg [63:0] action_r;

// always @(posedge clk) begin
//     action_r <= {act_out[1], act_out[0]};
// end

// reg [63:0] default_action;

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         default_action <= 64'b0;
//         action_valid <= 0;
//         action <= 0;
//     end else begin
//         if (wr_default)
//             default_action <= default_data;

//         // IMPORTANT: disable valid during write cycles
//         action_valid <= tcam_valid & ~wr_en;

//         if (tcam_valid & ~wr_en) begin
//             if (hit)
//                 action <= action_r;
//             else
//                 action <= default_action;
//         end
//     end
// end

// endmodule
















// `define USE_POWER_PINS
// module action_pipe #(
//     parameter ENTRIES  = 64,
//     parameter ACTION_W = 64
// )(
//     inout vccd1,
//     inout vssd1,

//     input clk,
//     input rst_n,

//     input tcam_valid,
//     input hit,
//     input [$clog2(ENTRIES)-1:0] hit_index,

//     output reg action_valid,
//     output reg [ACTION_W-1:0] action,

//     input wr_en,
//     input [$clog2(ENTRIES)-1:0] wr_addr,
//     input [ACTION_W-1:0] wr_data,

//     input wr_default,
//     input [ACTION_W-1:0] default_data
// );

// localparam IDX_W = $clog2(ENTRIES);

// // sram
// wire [31:0] act_out [0:1];

// genvar i;
// generate
//     for (i = 0; i < 2; i = i + 1) begin : ACTION_MEM

//         sram22_64x32m4w8 action_mem (
// `ifdef USE_POWER_PINS
//             .vdd(vccd1),
//             .vss(vssd1),
// `endif
//             .clk(clk),
//             .rstb(rst_n),
//             .ce(1'b1),

//             .we(wr_en),
//             .wmask(4'b1111),

//             .addr(wr_en ? wr_addr : wr_addr),

//             .din(wr_data[32*i +: 32]),
//             .dout(act_out[i])
//         );

//     end
// endgenerate


// // read

// // Stage 1: SRAM read data
// reg [63:0] action_r;

// always @(posedge clk) begin
//     action_r <= {act_out[1], act_out[0]};
// end


// // alignment

// // Delay control signals to match SRAM latency
// reg hit_d;
// reg [IDX_W-1:0] hit_index_d;
// reg tcam_valid_d;


// always @(posedge clk) begin
//     hit_d        <= hit;
//     hit_index_d  <= hit_index;
//     tcam_valid_d <= tcam_valid;

// end


// // default
// reg [63:0] default_action;

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n)
//         default_action <= 64'b0;
//     else if (wr_default)
//         default_action <= default_data;
// end


// // output
// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         action_valid <= 1'b0;
//         action       <= 64'b0;
//     end else begin

//         // valid aligned with SRAM output
//         action_valid <= tcam_valid_d & ~wr_en;

//         if (tcam_valid_d & ~wr_en) begin
//             if (hit_d)
//                 action <= action_r;        
//             else
//                 action <= default_action;
//         end
//     end
// end

// endmodule




