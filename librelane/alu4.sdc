# alu4 constraints, used for both PnR and signoff (see config.json).
create_clock [get_ports clk] -name clk -period 10.0
set_clock_uncertainty 0.25 [get_clocks clk]

set inputs_wo_clk [list [get_ports a*] [get_ports b*] [get_ports op*] [get_ports rst_n]]
set_input_delay 2.0 -clock [get_clocks clk] $inputs_wo_clk
set_output_delay 2.0 -clock [get_clocks clk] [all_outputs]

set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin Y $inputs_wo_clk
set_load 0.033 [all_outputs]

# ideal clocks before CTS, propagated after (same switch as LibreLane's base.sdc)
if { [info exists ::env(OPENLANE_SDC_IDEAL_CLOCKS)] && $::env(OPENLANE_SDC_IDEAL_CLOCKS) } {
    unset_propagated_clock [all_clocks]
} else {
    set_propagated_clock [all_clocks]
}
