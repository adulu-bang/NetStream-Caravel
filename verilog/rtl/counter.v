/// sta-blackbox
module counter (
`ifdef USE_POWER_PINS
    inout VPWR,
    inout VGND,
`endif
    input clk,
    input rst,
    output reg [7:0] count
);

always @(posedge clk) begin
    if (rst)
        count <= 8'd0;
    else
        count <= count + 1;
end

endmodule