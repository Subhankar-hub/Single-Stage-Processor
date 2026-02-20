# scripts/run_impl.tcl
# Open project and run implementation (place & route)
set proj_dir [pwd]
set proj_name "one_stage_cpu"

open_project $proj_dir/$proj_name.xpr

# Make sure synthesis is done
if {[get_property NEEDS_REFRESH [get_runs synth_1]]} {
    launch_runs synth_1 -jobs [expr {max(1, [exec nproc] / 2)}]
    wait_on_run synth_1
}

reset_run impl_1
launch_runs impl_1 -jobs [expr {max(1, [exec nproc] / 2)}]
wait_on_run impl_1

if {[get_property STATUS [get_runs impl_1]] ne "route_design Complete!"} {
    puts "ERROR: Implementation failed."
    exit 1
}

# Generate post-implementation reports
open_run impl_1
report_utilization -file $proj_dir/reports/impl_utilization.rpt
report_timing_summary -file $proj_dir/reports/impl_timing_summary.rpt
report_power -file $proj_dir/reports/impl_power.rpt
report_drc -file $proj_dir/reports/impl_drc.rpt

puts "Implementation complete. Reports in reports/"
close_project
