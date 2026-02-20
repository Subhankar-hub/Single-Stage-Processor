# scripts/create_project.tcl
# Create Vivado project, add sources, set device, configure simulation top
set proj_name "one_stage_cpu"
set proj_dir [pwd]

# device
set device "xc7k70tfbv676-1"

create_project $proj_name $proj_dir -part $device -force

# Add RTL sources
add_files -norecurse [list \
  $proj_dir/rtl/isa_defs.sv \
  $proj_dir/rtl/instruction_memory.sv \
  $proj_dir/rtl/data_memory.sv \
  $proj_dir/rtl/regfile.sv \
  $proj_dir/rtl/alu.sv \
  $proj_dir/rtl/control_unit.sv \
  $proj_dir/rtl/cpu_top.sv ]

# Add testbench sources to the simulation fileset
add_files -fileset sim_1 -norecurse [list \
  $proj_dir/tb/top_tb.sv \
  $proj_dir/tb/uvm/cpu_if.sv \
  $proj_dir/tb/uvm/cpu_pkg.sv \
  $proj_dir/tb/uvm/cpu_driver.sv \
  $proj_dir/tb/uvm/cpu_monitor.sv \
  $proj_dir/tb/uvm/cpu_agent.sv \
  $proj_dir/tb/uvm/cpu_scoreboard.sv \
  $proj_dir/tb/uvm/cpu_env.sv \
  $proj_dir/tb/uvm/cpu_test_base.sv \
  $proj_dir/tb/uvm/cpu_test_directed.sv \
  $proj_dir/tb/uvm/cpu_test_random.sv ]

# Set top-level for simulation
set_property top top_tb [get_filesets sim_1]

# Set simulation properties
set_property simulator_language Verilog [current_project]
set_property -name {xsim.compile.xvlog.more_options}    -value {-L uvm} -objects [get_filesets sim_1]
set_property -name {xsim.elaborate.xelab.more_options}   -value {-L uvm --timescale 1ns/1ps} -objects [get_filesets sim_1]

close_project
puts "Project created: $proj_name in $proj_dir"

