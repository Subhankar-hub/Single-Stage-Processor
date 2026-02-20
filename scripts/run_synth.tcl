# scripts/run_synth.tcl
# Open project and run synthesis
set proj_dir [pwd]
set proj_name "one_stage_cpu"

open_project $proj_dir/$proj_name.xpr

# Ensure design-level top is set
set_property top cpu_top [current_fileset]

reset_run synth_1
launch_runs synth_1 -jobs [expr {max(1, [exec nproc] / 2)}]
wait_on_run synth_1

if {[get_property STATUS [get_runs synth_1]] ne "synth_design Complete!"} {
    puts "ERROR: Synthesis failed."
    exit 1
}

# Generate utilisation and timing reports
open_run synth_1
report_utilization -file $proj_dir/reports/synth_utilization.rpt
report_timing_summary -file $proj_dir/reports/synth_timing_summary.rpt

puts "Synthesis complete. Reports in reports/"
close_project
