// `timescale 1ns / 1ps

// module tcam_ctrl_pipe #(
//     parameter KEY_W   = 128,
//     parameter ENTRIES = 16
// )(
//     input                       clk,
//     input                       rst_n,

    
//     input  [KEY_W-1:0]          key,// frm key builder
//     input                       key_valid,// frm pipeline reg

//     // frm control plane
//     input                       wr_en,//enable write signal by ctrl plane
//     input                       wr_is_mask,   // 0 = value, 1 = mask
//     input  [$clog2(ENTRIES)-1:0] wr_addr,//which entry to write
//     input  [KEY_W-1:0]          wr_data,//by processor

    
//     output reg                  hit,// 1 or 0 based on whether key has matched any rule
//     output reg [$clog2(ENTRIES)-1:0] hit_index//address which has hit 
// );

//     localparam IDX_W = $clog2(ENTRIES);// 4

    
//     reg [KEY_W-1:0] tcam_value [0:ENTRIES-1];//each tcam value is 128 bits,a nd there r 16 such tcam values
//     reg [KEY_W-1:0] tcam_mask  [0:ENTRIES-1];//similarly for mask

  
//     wire [ENTRIES-1:0] match;// each of 16 bits is 1 or 0 bsed on whether masked key and value hv matched

//     always @(posedge clk or negedge rst_n) begin//ctrl plane writes
//         if (!rst_n) begin

//         end else if (wr_en) begin
//             if (wr_is_mask)// its writing mask
//                 tcam_mask[wr_addr]  <= wr_data;
//             else
//                 tcam_value[wr_addr] <= wr_data;// its writing value
//         end
//     end

    
    
//     genvar i;
//     generate
//         for (i = 0; i < ENTRIES; i = i + 1) begin : TCAM_COMPARE// matching
//             assign match[i] =
//                 ((key & ~tcam_mask[i]) ==
//                  (tcam_value[i] & ~tcam_mask[i]));// is mask =1, thn ignore (just equates 0 to 0 for tht bit)                             
//         end
//     endgenerate

//     integer j;
//     always @(*) begin//low index proirity encoder
//         hit       = 1'b0;
//         hit_index = {IDX_W{1'b0}};

//         if (key_valid) begin
//             for (j = 0; j < ENTRIES; j = j + 1) begin
//                 if (match[j] && !hit) begin
//                     hit       = 1'b1;
//                     hit_index = j[IDX_W-1:0];
//                 end
//             end
//         end
//     end

// endmodule



// `define USE_POWER_PINS
// module tcam_ctrl_pipe #(
//     parameter KEY_W   = 128,
//     parameter ENTRIES = 32
// )(
//     inout vccd1,
//     inout vssd1,

//     input clk,
//     input rst_n,

//     input [KEY_W-1:0] key,
//     input key_valid,

//     input wr_en,
//     input wr_is_mask,
//     input [$clog2(ENTRIES)-1:0] wr_addr,
//     input [KEY_W-1:0] wr_data,

//     output reg hit,
//     output reg [$clog2(ENTRIES)-1:0] hit_index,

//     output reg tcam_valid
// );

// localparam IDX_W = $clog2(ENTRIES);


// wire [32:0] val_out [0:3];
// wire [32:0] mask_out [0:3];


// genvar i;
// generate
//     for (i = 0; i < 4; i = i + 1) begin : VALUE_MEM

//         sram_32x32 value_mem (
//             `ifdef USE_POWER_PINS
//     .vccd1(vccd1),
//     .vssd1(vssd1),
// `endif

//     .clk0(clk),
//       .csb0(1'b0),
//     .addr0({1'b0, (wr_en ? wr_addr : scan_addr)}),
//     .din0({1'b0, wr_data[32*i +: 32]}),
//     .spare_wen0(1'b0),
//     .dout0(val_out[i]),
//     .web0(~(wr_en && !wr_is_mask))
// );

//     end
// endgenerate

// generate
//     for (i = 0; i < 4; i = i + 1) begin : MASK_MEM

//        sram_32x32 mask_mem (
//      `ifdef USE_POWER_PINS
//     .vccd1(vccd1),
//     .vssd1(vssd1),
// `endif   

//     .clk0(clk),
//     .csb0(1'b0),
//     .addr0({1'b0, (wr_en ? wr_addr :  scan_addr)}),
//     .spare_wen0(1'b0),
//     .din0({1'b0, wr_data[32*i +: 32]}),
//     .dout0(mask_out[i]),
//     .web0(~(wr_en && wr_is_mask))
// );

//     end
// endgenerate


// reg [127:0] value_r, mask_r;

// always @(posedge clk) begin
//     value_r <= {val_out[3][31:0], val_out[2][31:0], val_out[1][31:0], val_out[0][31:0]};
//     mask_r  <= {mask_out[3][31:0], mask_out[2][31:0], mask_out[1][31:0], mask_out[0][31:0]};
// end


// reg [IDX_W-1:0] scan_addr;
// reg scanning;

// always @(posedge clk or negedge rst_n) begin
//     if (!rst_n) begin
//         scan_addr   <= 0;
//         scanning    <= 0;
//         hit         <= 0;
//         tcam_valid  <= 0;
//         hit_index   <= 0;

//     end else begin

//         // default
//         tcam_valid <= 0;

//         if (key_valid && !scanning) begin
//             scanning   <= 1;
//             scan_addr  <= 0;
//             hit        <= 0;
//             hit_index <=0;
//         end 

//         else if (scanning) begin

//             // match logic
//             if (((key & ~mask_r) == (value_r & ~mask_r)) && !hit) begin
//                 hit       <= 1;
//                 hit_index <= scan_addr;
//             end

//             scan_addr <= scan_addr + 1;

//             // END condition
//             if (scan_addr == ENTRIES-1) begin
//                 scanning   <= 0;
//                 tcam_valid <= 1;   
//             end
//         end
//     end
// end

// endmodule



`define USE_POWER_PINS
module tcam_ctrl_pipe #(
    parameter KEY_W   = 128,
    parameter ENTRIES = 32
)(
    inout vccd1,
    inout vssd1,

    input clk,
    input rst_n,

    input [KEY_W-1:0] key,
    input key_valid,

    input wr_en,
    input wr_is_mask,
    input [$clog2(ENTRIES)-1:0] wr_addr,
    input [KEY_W-1:0] wr_data,

    output reg hit,
    output reg [$clog2(ENTRIES)-1:0] hit_index,

    output reg tcam_valid
);

localparam IDX_W = $clog2(ENTRIES);


wire [255:0] val_out;
wire [255:0] mask_out;


sky130_sram_1kbyte_1rw1r_32x256_8 value_mem (
`ifdef USE_POWER_PINS
    .vccd1(vccd1),
    .vssd1(vssd1),
`endif

    .clk0(clk),
    .csb0(1'b0),
    .web0(~(wr_en && !wr_is_mask)),

    .addr0(wr_en ? wr_addr : scan_addr),
    .din0({128'b0, wr_data}),   // write lower 128 bits
    .dout0(val_out),

    .wmask0(4'b1111),

    // second port unused
    .clk1(clk),
    .csb1(1'b1),
    .addr1(0),
    .dout1()
);

sky130_sram_1kbyte_1rw1r_32x256_8 mask_mem (
`ifdef USE_POWER_PINS
    .vccd1(vccd1),
    .vssd1(vssd1),
`endif

    .clk0(clk),
    .csb0(1'b0),
    .web0(~(wr_en && wr_is_mask)),

    .addr0(wr_en ? wr_addr : scan_addr),
    .din0({128'b0, wr_data}),
    .dout0(mask_out),

    .wmask0(4'b1111),

 
    .clk1(clk),
    .csb1(1'b1),
    .addr1(0),
    .dout1()
);


reg [127:0] value_r, mask_r;

always @(posedge clk) begin
    value_r <= val_out[127:0];
    mask_r  <= mask_out[127:0];
end



reg [IDX_W-1:0] scan_addr;
reg scanning;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        scan_addr   <= 0;
        scanning    <= 0;
        hit         <= 0;
        tcam_valid  <= 0;
        hit_index   <= 0;

    end else begin

        tcam_valid <= 0;

        if (key_valid && !scanning) begin
            scanning   <= 1;
            scan_addr  <= 0;
            hit        <= 0;
            hit_index  <= 0;
        end 

        else if (scanning) begin

            if (((key & ~mask_r) == (value_r & ~mask_r)) && !hit) begin
                hit       <= 1;
                hit_index <= scan_addr;
            end

            scan_addr <= scan_addr + 1;

            if (scan_addr == ENTRIES-1) begin
                scanning   <= 0;
                tcam_valid <= 1;   
            end
        end
    end
end

endmodule