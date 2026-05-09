yosys -import
read_verilog -sv /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/defines.v
read_verilog -sv /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/user_defines.v
read_verilog -sv /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/action_drain_ctrl_upper.v
read_verilog -sv /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/action_pipe.v
read_verilog -sv /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/header_buffer_pipe_fifo.v
read_verilog -sv /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/header_to_parser_pipe_reg.v
read_verilog -sv /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/key_builder_pipe.v
read_verilog -sv /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/mac_rx_fifo_final.v
read_verilog -sv /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/packet_fifo_upper.v
read_verilog -sv /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/parser_fsm_pipe_2.v
read_verilog -sv /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/parser_to_key_pipe.v
read_verilog -sv /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/rewrite_mux_upper.v
read_verilog -sv /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/tcam_ctrl_pipe.v
read_verilog -sv /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/tcam_to_action_pipe.v
read_verilog -sv /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/RAM32_behav.v
read_verilog -sv /mnt/c/Users/KRISH\ MEHTA/Downloads/rtlmain/rtl/dataplane_top.v

hierarchy -check -top dataplane_top
synth -top dataplane_top

dfflibmap -liberty /home/krish1002/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
abc -liberty /home/krish1002/pdk/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
clean
write_verilog -noattr /mnt/c/Users/KRISH\ MEHTA/.gemini/antigravity/scratch/dataplane_top_gls.v
