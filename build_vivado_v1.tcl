
# Get Environment Variables
set SOURCE_FILE $::env(SOURCE_FILE)
set XDC_FILES   $::env(XDC_FILES)
set PRJ_PART    $::env(PRJ_PART)
set PROJECT     $::env(PROJECT)
set PROJ_DIR    $::env(PROJ_DIR)
set OUT_DIR     $::env(OUT_DIR)
set TOP_DIR     $::env(TOP_DIR)
set VIVADO_DIR  $::env(VIVADO_DIR)

# Setup Args
set SYNTH_ARGS ""
set OPT_ARGS   ""
set PLACE_ARGS ""
set ROUTE_ARGS ""

# Run source file commands
source ${SOURCE_FILE}

# Read XDC FILES
read_xdc ${XDC_FILES}

# Pre-synthesis Target Script
source ${VIVADO_DIR}/pre_synthesis.tcl

# Message Suppression: INFO: Synthesizing Module messages
set_msg_config -suppress -id {Synth 8-256}
set_msg_config -suppress -id {Synth 8-113}
set_msg_config -suppress -id {Synth 8-226}
set_msg_config -suppress -id {Synth 8-4472}

# Message Suppression: WARNING: "ignoring unsynthesizable construct" due to assert error checking
set_msg_config -suppress -id {Synth 8-312}

# Messages: Change from WARNING to ERROR
set_msg_config -id {Vivado 12-508} -new_severity {ERROR}

# Messages: Change from CRITICAL_WARNING to ERROR
set_msg_config -id {Vivado 12-1387} -new_severity {ERROR}

# Synthesize
synth_design -top ${PROJECT} -part ${PRJ_PART} {*}${SYNTH_ARGS}

# Checkpoint
write_checkpoint -quiet -force ${PROJECT}_post_synth.dcp

# Post-synthesis Target Script
source ${VIVADO_DIR}/post_synthesis.tcl

# Optimize
opt_design {*}${OPT_ARGS}

# Power optimization
power_opt_design -quiet 

# Place
place_design -quiet {*}${PLACE_ARGS}

# Checkpoint
write_checkpoint -quiet -force ${PROJECT}_post_place.dcp

# Route
phys_opt_design -quiet 
route_design {*}${ROUTE_ARGS}

# Reports are not generated by default
report_timing_summary -quiet -file ${PROJECT}_post_route_timing.txt
report_utilization -quiet -file ${PROJECT}_post_route_util.txt
report_drc -quiet -file ${PROJECT}_post_route_drc.txt
report_power -quiet -file ${PROJECT}_post_route_power.txt

# Save the database after post route
write_checkpoint -quiet -force ${PROJECT}_post_route.dcp

# Post-palce & Route Target Script
source ${VIVADO_DIR}/post_route.tcl

# Write Bitstream
write_bitstream -quiet -force ${PROJECT}.bit 
