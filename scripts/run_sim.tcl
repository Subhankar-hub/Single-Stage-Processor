# scripts/run_sim.tcl
# Compile RTL + UVM tests and run simulation (Vivado/XSim)
set proj_dir [pwd]
set sim_top "top_tb"

# Vivado's bundled GCC doesn't know Debian multiarch include/lib paths
set ::env(CPATH) "/usr/include/x86_64-linux-gnu"
set ::env(LIBRARY_PATH) "/usr/lib/x86_64-linux-gnu"

# Clean previous simulation products
file delete -force xsim.dir work .Xil

# Compile SystemVerilog sources with xvlog
# -L uvm: link against Vivado's pre-compiled UVM library
# Interface and package files must come before modules that use them
puts "Compiling RTL and TB..."
exec xvlog -sv -L uvm \
  $proj_dir/rtl/isa_defs.sv \
  $proj_dir/rtl/instruction_memory.sv \
  $proj_dir/rtl/data_memory.sv \
  $proj_dir/rtl/regfile.sv \
  $proj_dir/rtl/alu.sv \
  $proj_dir/rtl/control_unit.sv \
  $proj_dir/rtl/cpu_top.sv \
  $proj_dir/tb/uvm/cpu_if.sv \
  $proj_dir/tb/uvm/cpu_pkg.sv \
  $proj_dir/tb/uvm/cpu_driver.sv \
  $proj_dir/tb/uvm/cpu_monitor.sv \
  $proj_dir/tb/uvm/cpu_agent.sv \
  $proj_dir/tb/uvm/cpu_scoreboard.sv \
  $proj_dir/tb/uvm/cpu_env.sv \
  $proj_dir/tb/uvm/cpu_test_base.sv \
  $proj_dir/tb/uvm/cpu_test_directed.sv \
  $proj_dir/tb/uvm/cpu_test_random.sv \
  $proj_dir/tb/top_tb.sv

# Elaborate with UVM support
puts "Elaborating..."
exec xelab $sim_top -debug wave -L uvm -s ${sim_top}_sim --timescale 1ns/1ps

puts "Running simulation..."
exec xsim ${sim_top}_sim -R
