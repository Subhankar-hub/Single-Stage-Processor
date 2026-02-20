# scripts/run_bitstream.tcl
# Open project and generate bitstream
set proj_dir [pwd]
set proj_name "one_stage_cpu"

open_project $proj_dir/$proj_name.xpr

# Ensure implementation is done, then generate bitstream
if {[get_property NEEDS_REFRESH [get_runs impl_1]]} {
    launch_runs impl_1 -jobs [expr {max(1, [exec nproc] / 2)}]
    wait_on_run impl_1
}

launch_runs impl_1 -to_step write_bitstream -jobs [expr {max(1, [exec nproc] / 2)}]
wait_on_run impl_1

if {[get_property STATUS [get_runs impl_1]] ne "write_bitstream Complete!"} {
    puts "ERROR: Bitstream generation failed."
    exit 1
}

puts "Bitstream generated: $proj_dir/$proj_name.runs/impl_1/cpu_top.bit"
close_project
