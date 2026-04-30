#create_clock -name clk -period 17 [get_ports clk]

#set_input_delay  3 -clock clk [all_inputs]
#set_output_delay 2 -clock clk [all_outputs]


#create_clock -name clk -period 20 [get_ports clk]

#set_input_delay 3 -clock clk \
    [remove_from_collection [all_inputs] [get_ports clk]]

#set_output_delay 2 -clock clk [all_outputs]

create_clock -name clk -period 25 [get_ports clk]

set_clock_uncertainty 0.2 [get_clocks clk]
set_clock_transition 0.6 [get_clocks clk]
set_clock_latency -source -max 5.6 [get_clocks clk]
set_clock_latency -source -min 4.6 [get_clocks clk]

set_input_delay 5 -clock clk [all_inputs]

set_output_delay 4 -clock clk [all_outputs]

set_input_transition 0.5 [all_inputs]
