`define USE_POWER_PINS
`timescale 1ns / 1ps
module mac_rx_fifo_final #(
    parameter DEPTH = 32,               // must be >= 12
    parameter ADDR_W = 5             // log2(DEPTH)
)(
    input            clk,
    input            rst_n,

    // mac side
    input            rx_valid,
    input  [7:0]     rx_data,
    input            rx_last,
    output           rx_ready,

    // header buffer side
    output reg       fifo_valid,
    output reg [7:0] fifo_data,
    output reg       fifo_last,
    input            fifo_ready,

    output fifo_fire
);

    // storage
    reg [7:0] data_mem [0:DEPTH-1];
    reg       last_mem [0:DEPTH-1];

    

    reg [ADDR_W:0] wr_ptr;
    reg [ADDR_W:0] rd_ptr;
    reg [ADDR_W:0] count;
    reg fifo_valid_new;


    integer i;


    assign rx_ready = (count < DEPTH);

    wire write_en = rx_valid && rx_ready;
    wire read_en = (count != 0) && fifo_valid_new && fifo_ready;

    assign fifo_fire= read_en;


    wire [ADDR_W-1:0] rd_addr =
    (count == 0 && write_en) ? wr_ptr[ADDR_W-1:0]
                             : rd_ptr[ADDR_W-1:0];

    
  



    always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_ptr     <= 0;
        rd_ptr     <= 0;

        count      <= 0;
        fifo_valid <= 0;
        fifo_valid_new <=0;
        fifo_data  <= 8'h00;
        fifo_last  <= 1'b0;
        for (i = 0; i < DEPTH; i = i + 1) begin
                data_mem[i] <= 8'h00;
                last_mem[i] <= 1'b0;
            end
    end else begin
        
        if (write_en) begin
            data_mem[wr_ptr[ADDR_W-1:0]] <= rx_data;
            last_mem[wr_ptr[ADDR_W-1:0]] <= rx_last;
            wr_ptr <= wr_ptr + 1;
        end
        if (read_en) begin
            rd_ptr <= rd_ptr + 1;
        end

        case ({write_en, read_en})
            2'b10: count <= count + 1;
            2'b01: count <= count - 1;
            default: ;
        endcase

        if ((count != 0) || write_en) begin
            fifo_valid_new <= 1'b1;
            fifo_data  <= data_mem[rd_addr];
            fifo_last  <= last_mem[rd_addr];
        end else begin
            fifo_valid_new <= 1'b0;
            fifo_last  <= 1'b0;
        end

        if(count!=0) fifo_valid<=1'b1;
        else fifo_valid<= 1'b0;



    end
end
endmodule








