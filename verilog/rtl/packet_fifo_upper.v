`define USE_POWER_PINS
`timescale 1ns / 1ps

module packet_fifo_upper #(
    parameter DEPTH    = 1024,
    parameter ADDR_W   = $clog2(DEPTH),
    parameter ACTION_W = 64
)(
    input  wire clk,
    input  wire rst_n,

    // write side (from lower fifo / MAC)
    input  wire       wr_valid,
    input  wire [7:0] wr_data,
    input  wire       wr_last,
    output wire       wr_ready,

    // read side
    output reg        rd_valid,
    output reg [7:0]  rd_data,
    output reg        rd_last,
    input  wire       rd_ready,

    // action interface
    input  wire              action_valid,
    input  wire [ACTION_W-1:0] action_in,

    // outputs
    output reg               pkt_sop,
    output reg [ACTION_W-1:0] action_out
);

//dta storage
    reg [7:0] mem      [0:DEPTH-1];
    reg       mem_last [0:DEPTH-1];

    reg [ADDR_W:0] wr_ptr, rd_ptr;
    reg [ADDR_W:0] count;

    assign wr_ready = (count < DEPTH);

    wire write_en = wr_valid && wr_ready;
    wire read_en  = rd_valid && rd_ready; 

   //action ownership
    reg [ACTION_W-1:0] action_fifo [0:DEPTH-1];
    reg [ADDR_W:0] action_wr_ptr, action_rd_ptr;

    wire action_available = (action_wr_ptr != action_rd_ptr);

    //write
    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (write_en) begin
            mem[wr_ptr[ADDR_W-1:0]]      <= wr_data;
            mem_last[wr_ptr[ADDR_W-1:0]] <= wr_last;
            wr_ptr <= wr_ptr + 1;
        end
    end

    //action queue
    always @(posedge clk) begin
        if (!rst_n) begin
            action_wr_ptr <= 0;
        end else if (action_valid) begin
            action_fifo[action_wr_ptr] <= action_in;
            action_wr_ptr <= action_wr_ptr + 1;
        end
    end



//read
reg draining;

always @(posedge clk) begin
    if (!rst_n) begin
        rd_ptr        <= 0;
        rd_valid      <= 0;
        rd_last       <= 0;
        draining      <= 0;
        pkt_sop       <= 0;
        action_out    <= 0;
        action_rd_ptr <= 0;
    end else begin
        // defaults
        rd_valid <= 0;
        rd_last  <= 0;
        pkt_sop  <= 0;

        
        if (!draining && action_available && count != 0) begin
            draining     <= 1'b1;
            pkt_sop      <= 1'b1;
            
            action_out    <= action_fifo[action_rd_ptr];
            action_rd_ptr <= action_rd_ptr + 1;
        end

        
        if (draining && count != 0) begin
            rd_valid <= 1'b1;
            rd_data  <= mem[rd_ptr[ADDR_W-1:0]];
            rd_last  <= mem_last[rd_ptr[ADDR_W-1:0]];
        end

        
        if (draining /*&& rd_valid*/ && rd_ready) begin
            

            rd_ptr <= rd_ptr + 1;

            if (mem_last[rd_ptr[ADDR_W-1:0]])
                draining <= 1'b0;
        end
    end
end


   //counting
    always @(posedge clk) begin
        if (!rst_n) begin
            count <= 0;
        end else begin
            case ({write_en, read_en})
                2'b10: count <= count + 1;
                2'b01: count <= count - 1;
                default: ;
            endcase
        end
    end

endmodule
