
## --- ALL Efabless/Caravel Environment Variables ---
export CARAVEL_PATH         = ../../../../caravel/verilog
export VERILOG_PATH         = ../../../../mgmt_core_wrapper/verilog
export USER_PROJECT_VERILOG = ../../../../verilog
export MCW_ROOT             = ../../../../mgmt_core_wrapper
export CORE_VERILOG_PATH    = ../../../../mgmt_core_wrapper/verilog
export PDK_ROOT             = /home/parthip_dev/NetStream-Caravel/dependencies/pdks/ciel/sky130/versions/3e0e31dcce8519a7dbb82590346db16d91b7244f
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
	iverilog -g2012 \
		-DFUNCTIONAL -DSIM -DUNIT_DELAY=\#1 -DUSE_POWER_PINS \
		-I ../../../../verilog/rtl \
		-I ../../../../caravel/verilog/rtl \
		-o sim.out \
		../../../../caravel/verilog/rtl/defines.v \
		-f ../../../../mgmt_core_wrapper/verilog/includes/includes.rtl.caravel \
		tb_firmware.v \
		../../../../verilog/rtl/user_project_wrapper.v \
		../../../../verilog/rtl/dataplane_top_stub.v
	vvp sim.out | tee sim.log

wave:
	gtkwave tb.vcd &

clean:
	rm -f firmware.elf firmware.hex sim.out tb.vcd sim.log