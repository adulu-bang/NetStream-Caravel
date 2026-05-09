#!/bin/bash
cd /mnt/c/Users/KRISH\ MEHTA/.gemini/antigravity/scratch

echo "=== Compiling RTL ==="
iverilog -g2012 -o sim_rtl_30 \
    /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/action_drain_ctrl_upper.v \
    /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/action_pipe.v \
    /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/dataplane_top.v \
    /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/header_buffer_pipe_fifo.v \
    /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/header_to_parser_pipe_reg.v \
    /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/key_builder_pipe.v \
    /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/mac_rx_fifo_final.v \
    /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/packet_fifo_upper.v \
    /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/parser_fsm_pipe_2.v \
    /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/parser_to_key_pipe.v \
    /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/RAM32_behav.v \
    /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/rewrite_mux_upper.v \
    /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/tcam_ctrl_pipe.v \
    /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/tcam_to_action_pipe.v \
    /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/defines.v \
    /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/user_defines.v \
    tb_30_cases.v

if [ $? -eq 0 ]; then
    echo "=== Running RTL Sim ==="
    vvp sim_rtl_30 > rtl_30.full.log 2>&1
    grep "DATA:" rtl_30.full.log > rtl_30.log
else
    echo "RTL Compilation failed!"
    exit 1
fi

echo "=== Compiling Netlist (Zero-Delay) ==="
iverilog -g2012 -D GL -D FUNCTIONAL -D UNIT_DELAY=#1 \
    /home/krish1002/pdk/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v \
    /home/krish1002/pdk/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v \
    dataplane_top_gls.v \
    tb_30_cases.v \
    -o sim_gls_30

if [ $? -eq 0 ]; then
    echo "=== Running Netlist Sim ==="
    vvp sim_gls_30 > gls_30.full.log 2>&1
    grep "DATA:" gls_30.full.log > gls_30.log
else
    echo "Netlist Compilation failed!"
    exit 1
fi

echo "=== Diffing Results ==="
diff rtl_30.log gls_30.log > diff_30.log
if [ -s diff_30.log ]; then
    echo "MISMATCH! Showing differences:"
    cat diff_30.log
else
    echo "MATCH! Both simulations produced identical logs."
fi
