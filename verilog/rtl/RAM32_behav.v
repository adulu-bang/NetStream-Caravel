module RAM32 (
    input CLK,
    input EN0,

    input VPWR,
    input VGND,

    input [4:0] A0,
    input [31:0] Di0,
    output reg [31:0] Do0,
    input [3:0] WE0
);

reg [31:0] mem [0:31];

integer i;

initial begin
    for (i = 0; i < 32; i = i + 1)
        mem[i] = 32'h0;
end

always @(posedge CLK) begin
    if (EN0) begin

        // WRITE
        if (WE0 != 4'b0000)
            mem[A0] <= Di0;

        // READ
        Do0 <= mem[A0];
    end
end

endmodule