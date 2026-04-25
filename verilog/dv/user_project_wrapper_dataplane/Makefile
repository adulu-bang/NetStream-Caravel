
## --- ALL Efabless/Caravel Environment Variables ---
export CARAVEL_PATH         = ../../../../caravel/verilog
export VERILOG_PATH         = ../../../../mgmt_core_wrapper/verilog
export USER_PROJECT_VERILOG = ../../../verilog
export MCW_ROOT             = ../../../../mgmt_core_wrapper
export CORE_VERILOG_PATH    = ../../../../mgmt_core_wrapper/verilog
export PDK_ROOT             = ..
export PDK                  = sky130A

RISCV_GCC     = riscv64-unknown-elf-gcc
RISCV_OBJCOPY = riscv64-unknown-elf-objcopy

.PHONY: all sim wave clean

firmware.hex: main.c start.s sections.lds
	$(RISCV_GCC) \
		-march=rv32imc -mabi=ilp32 \
		-Wl,-Bstatic,-T,sections.lds,--strip-debug \
		-ffreestanding -nostdlib \
		-o firmware.elf \
		start.s main.c
	$(RISCV_OBJCOPY) -O verilog firmware.elf firmware.hex
	sed -i 's/@10000000/@00000000/g' firmware.hex
	@echo "Firmware compiled OK"

sim: firmware.hex
	iverilog -g2012 -s user_project_wrapper \
		-DFUNCTIONAL -DSIM -DUNIT_DELAY=\#1 -DUSE_POWER_PINS \
		-I ../../../../verilog/rtl \
		-I ../../../../caravel/verilog/rtl \
		-o sim.out \
		-f ../../../verilog/includes/includes.rtl.caravel_user_project \
		tb_firmware.v
	vvp sim.out | tee sim.log

wave:
	gtkwave tb.vcd &

clean:
	rm -f firmware.elf firmware.hex sim.out tb.vcd sim.log
