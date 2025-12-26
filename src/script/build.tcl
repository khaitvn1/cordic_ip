# =============================================================================
# Xilinx Vivado Build Script for Pipelined CORDIC IP
# Creates project, adds RTL + XDC, runs synth/impl, writes bit + reports
# =============================================================================

# Resolve repo root relative to this script (works as long as original repo is cloned)
set script_dir [file dirname [file normalize [info script]]]
set repo_root  [file normalize "$script_dir/.."]

set project_name "pipelined_cordic_ip"
set project_dir  "$repo_root/build/vivado"
set part_name    "xc7a35tcpg236-1"
set top_name     "cordic_top"

# Source RTL files
set src_files [list \
  "$repo_root/src/rtl/cordic_pkg.sv" \
  "$repo_root/src/rtl/cordic_stage.sv" \
  "$repo_root/src/rtl/cordic_preproc.sv" \
  "$repo_root/src/rtl/cordic_preproc_vec.sv" \
  "$repo_root/src/rtl/cordic_rotator.sv" \
  "$repo_root/src/rtl/cordic_vectoring.sv" \
  "$repo_root/src/rtl/cordic_top.sv" \
]

# XDC constraints file
set xdc_file "$repo_root/src/constraint/pipelined_cordic_constraints.xdc"

# Prep output dirs
file mkdir $project_dir
set report_dir "$project_dir/reports"
set bit_dir    "$project_dir/bit"
file mkdir $report_dir
file mkdir $bit_dir

puts "=== Vivado build: $project_name ==="
puts "Repo root   : $repo_root"
puts "Project dir : $project_dir"
puts "Top module  : $top_name"
puts "Part        : $part_name"

# Create project
create_project $project_name $project_dir -part $part_name -force
set_property target_language Verilog [current_project]

# Add design sources
add_files -norecurse $src_files

# Add constraint file
add_files -fileset constrs_1 -norecurse $xdc_file

# Set top module explicitly on sources_1
set_property top $top_name [get_filesets sources_1]
update_compile_order -fileset sources_1

# Strategies for synthesis and implementation
set_property strategy Vivado_Synthesis_Defaults [get_runs synth_1]
set_property strategy Vivado_Implementation_Defaults [get_runs impl_1]

# Run synthesis
puts "=== Running synthesis ==="
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Check synthesis results (more robust than PROGRESS alone)
set synth_status [get_property STATUS [get_runs synth_1]]
if {![string match "*Complete*" $synth_status]} {
    error "Synthesis failed or did not complete. STATUS=$synth_status"
}

# Open synthesized design and generate reports
open_run synth_1
report_utilization -hierarchical -file "$report_dir/util_synth.rpt"
report_timing_summary -delay_type max -file "$report_dir/timing_synth.rpt"
report_power -file "$report_dir/power_synth.rpt"

# Run implementation (PnR) + Bitstream
puts "=== Running implementation (through write_bitstream) ==="
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

set impl_status [get_property STATUS [get_runs impl_1]]
if {![string match "*Complete*" $impl_status]} {
    error "Implementation failed or did not complete. STATUS=$impl_status"
}

open_run impl_1

# Reports after PnR
report_utilization -hierarchical -file "$report_dir/util_impl.rpt"
report_timing_summary -delay_type max -file "$report_dir/timing_impl.rpt"
report_drc -file "$report_dir/drc_impl.rpt"
report_clock_utilization -file "$report_dir/clock_util_impl.rpt"

# Copy/emit bitstream into a repo location
set impl_dir [get_property DIRECTORY [get_runs impl_1]]
set src_bit "$impl_dir/${top_name}.bit"

if {[file exists $src_bit]} {
    file copy -force $src_bit "$bit_dir/${top_name}.bit"
    puts "Bitstream copied to: $bit_dir/${top_name}.bit"
} else {
    puts "WARN: run output bit not found, calling write_bitstream explicitly..."
    write_bitstream -force "$bit_dir/${top_name}.bit"
}

puts "=== Build complete ==="
puts "Reports: $report_dir"
puts "Bit: $bit_dir/${top_name}.bit"

close_project
exit
