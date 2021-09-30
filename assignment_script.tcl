#Author: Onica Alexandru Valentin

#project creation
create_project core C:/core -part xc7z020clg484-1 -force
set_property board_part em.avnet.com:zed:part0:1.4 [current_project]
set_property target_language VHDL [current_project]


#ipcore generation
create_bd_design "design_1"
create_bd_cell -type ip -vlnv xilinx.com:ip:c_addsub:12.0 c_addsub_0

##In following we find 4 ip configurations, uncomment the desired line. 
## --------- Remember to upadate the latency constant in the testbench file at line 27 ---------
set implem "Fabric"; set cnfg "Automatic"; set lat 3; # 1_ fabric latency = 3
#set implem "Fabric"; set cnfg "Manual"; set lat 8; # 2_ fabric latency = 8
#set implem "DSP48"; set cnfg "Automatic"; set lat 2; # 3_ DSP48 latency = 2
#set implem "DSP48"; set cnfg "Manual"; set lat 1; # 4_ DSP48 latency = 1

set_property -quiet -dict [list CONFIG.Implementation $implem CONFIG.Latency_Configuration $cnfg CONFIG.Latency $lat] [get_bd_cells c_addsub_0]
set_property -dict [list CONFIG.B_Type.VALUE_SRC USER CONFIG.B_Width.VALUE_SRC USER CONFIG.A_Width.VALUE_SRC USER CONFIG.A_Type.VALUE_SRC USER] [get_bd_cells c_addsub_0]
set_property -dict [list CONFIG.A_Type {Unsigned} CONFIG.B_Type {Unsigned} CONFIG.A_Width {32} CONFIG.B_Width {32} CONFIG.Add_Mode {Subtract} CONFIG.Out_Width {33} CONFIG.SCLR {true} CONFIG.B_Value {00000000000000000000000000000000}] [get_bd_cells c_addsub_0]
create_bd_port -dir I -from 31 -to 0 -type data A
connect_bd_net [get_bd_pins /c_addsub_0/A] [get_bd_ports A]
create_bd_port -dir I -from 31 -to 0 -type data B
connect_bd_net [get_bd_pins /c_addsub_0/B] [get_bd_ports B]
create_bd_port -dir I -type ce CE
connect_bd_net [get_bd_pins /c_addsub_0/CE] [get_bd_ports CE]
create_bd_port -dir I -type rst SCLR
set_property CONFIG.POLARITY [get_property CONFIG.POLARITY [get_bd_pins c_addsub_0/SCLR]] [get_bd_ports SCLR]
connect_bd_net [get_bd_pins /c_addsub_0/SCLR] [get_bd_ports SCLR]
create_bd_port -dir O -from 32 -to 0 -type data S
connect_bd_net [get_bd_pins /c_addsub_0/S] [get_bd_ports S]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "New External Port (100 MHz)" }  [get_bd_pins c_addsub_0/CLK]

#design wrapping
make_wrapper -files [get_files C:/core/core.srcs/sources_1/bd/design_1/design_1.bd] -top
import_files -force -norecurse C:/core/core.srcs/sources_1/bd/design_1/hdl/design_1_wrapper.vhd

#clock constraint
add_files -fileset constrs_1 C:/core/assignment_constraint.xdc
set_property target_constrs_file C:/core/assignment_constraint.xdc [current_fileset -constrset]

#synthesis
launch_runs synth_1 -jobs 6
wait_on_run synth_1

#implementation
launch_runs impl_1 -jobs 6
wait_on_run impl_1

#testbench inclusion
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse {C:/core/u32_subtractor_tb.vhd C:/core/vector_files/vector.txt C:/core/vector_files/expected.txt}
update_compile_order -fileset sim_1
set_property file_type {VHDL 2008} [get_files u32_subtractor_tb.vhd]
add_files -fileset sim_1 -norecurse C:/core/custom_waveforms.wcfg
set_property xsim.view C:/core/custom_waveforms.wcfg [get_filesets sim_1]

#simulation
set total_time [expr 150+($lat+162)*10]; #total time to run is equal to an initial delay of 120 plus a 30 seconds after finishing (150), + T (period) * ( 162 test vectors plus latency (pipelined))
set_property -name {xsim.simulate.runtime} -value ${total_time}ns -objects [get_filesets sim_1]
launch_simulation -mode post-implementation -type timing 