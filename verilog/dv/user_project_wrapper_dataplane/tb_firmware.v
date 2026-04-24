`default_nettype wire
`timescale 1ns/1ps
`define USE_POWER_PINS

module tb_firmware;
    // ─── Internal Registers ───────────────────────────
    reg clk_reg;
    reg RSTB;
    reg pwr1, pwr2, pwr3, pwr4;

    // ─── Dedicated Wires for INOUT Ports ──────────────
    // You cannot connect regs or constants directly to inout ports.
    // We create a separate wire for every port to avoid multi-driver errors.
    wire clock = clk_reg;
    
    wire vddio_w = pwr1;
    wire vdda_w  = pwr2;
    wire vccd_w  = pwr3;
    wire vdda1_w = pwr4;
    wire vdda2_w = pwr4;
    wire vccd1_w = pwr3;
    wire vccd2_w = pwr3;

    wire vssio_w = 1'b0;
    wire vssa_w  = 1'b0;
    wire vssd_w  = 1'b0;
    wire vssa1_w = 1'b0;
    wire vssa2_w = 1'b0;
    wire vssd1_w = 1'b0;
    wire vssd2_w = 1'b0;

    // ─── IO Wires ─────────────────────────────────────
    wire gpio;
    wire [37:0] mprj_io;
    wire flash_csb;
    wire flash_clk;
    wire flash_io0;
    wire flash_io1;

    // ─── Clock Generation ─────────────────────────────
    initial clk_reg = 0;
    always #12.5 clk_reg <= ~clk_reg; // 40 MHz clock

    // ─── Power & Reset Sequence ───────────────────────
    initial begin
        RSTB = 0;
        pwr1 = 0; pwr2 = 0; pwr3 = 0; pwr4 = 0;
        #200;
        pwr1 = 1; pwr2 = 1; // 3.3V first
        #200;
        pwr3 = 1; pwr4 = 1; //1.8V next
        #200;
        RSTB = 1; // Release reset
    end

    // ─── Snoop Wishbone for Completion ────────────────
        always @(posedge clock) begin
        if (uut.chip_core.mprj.wbs_cyc_i &&
            uut.chip_core.mprj.wbs_stb_i &&
            uut.chip_core.mprj.wbs_we_i  &&
            uut.chip_core.mprj.wbs_ack_o) begin
            $display("[WB] addr=0x%08X data=0x%08X",
                uut.chip_core.mprj.wbs_adr_i,
                uut.chip_core.mprj.wbs_dat_i);
            if (uut.chip_core.mprj.wbs_adr_i == 32'h3000002C) begin
                $display("=== Firmware done — default action written ===");
                #1000;
                $finish;
            end
        end
    end

    // Add this to see when wb_enable fires
    always @(posedge clock) begin
        if (uut.chip_core.mprj.wbs_cyc_i)
            $display("[WB_CYC] at time %0t", $time);
    end

    // ─── Caravel SoC Instantiation ────────────────────
    caravel uut (
        .vddio    (vddio_w),
        .vssio    (vssio_w),
        .vdda     (vdda_w),
        .vssa     (vssa_w),
        .vccd     (vccd_w),
        .vssd     (vssd_w),
        .vdda1    (vdda1_w),
        .vssa1    (vssa1_w),
        .vdda2    (vdda2_w),
        .vssa2    (vssa2_w),
        .vccd1    (vccd1_w),
        .vssd1    (vssd1_w),
        .vccd2    (vccd2_w),
        .vssd2    (vssd2_w),
        .clock    (clock),
        .resetb   (RSTB),
        .gpio     (gpio),
        .mprj_io  (mprj_io),
        .flash_csb(flash_csb),
        .flash_clk(flash_clk),
        .flash_io0(flash_io0),
        .flash_io1(flash_io1)
    );

    // ─── SPI Flash Instantiation ──────────────────────
    spiflash #(
        .FILENAME("firmware.hex")
    ) spiflash (
        .csb(flash_csb),
        .clk(flash_clk),
        .io0(flash_io0),
        .io1(flash_io1),
        .io2(),
        .io3()
    );
    
    // ─── Simulation Timeout ───────────────────────────
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb_firmware); // Changed to match your new module name
        #50000000; // Booting the RISC-V takes time. Timeout is set high.
        $display("TIMEOUT! Simulation stuck.");
        $finish;
    end
endmodule