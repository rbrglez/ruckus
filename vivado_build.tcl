##############################################################################
## This file is part of 'SLAC Firmware Standard Library'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'SLAC Firmware Standard Library', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

## Project Batch-Mode Run Script

########################################################
## Get variables and Custom Procedures
########################################################
set RUCKUS_DIR $::env(RUCKUS_DIR)
source -quiet ${RUCKUS_DIR}/vivado_env_var.tcl
source -quiet ${RUCKUS_DIR}/vivado_proc.tcl

########################################################
## Open the project
########################################################

# Open the project
open_project -quiet ${VIVADO_PROJECT}

# Setup project properties
source -quiet ${RUCKUS_DIR}/vivado_properties.tcl

# Setup project messaging
source -quiet ${RUCKUS_DIR}/vivado_messages.tcl

########################################################
## Update the complie order
########################################################
update_compile_order -quiet -fileset sources_1
update_compile_order -quiet -fileset sim_1

########################################################
## Check project configuration for errors
########################################################
if { [CheckPrjConfig] != true } {
   exit -1
}

########################################################
## Check if we need to clean up or stop the implement
########################################################
if { [CheckImpl] != true } {
   reset_run impl_1
}

########################################################
## Check if we need to clean up or stop the synthesis
########################################################
if { [CheckSynth] != true } {
   reset_run synth_1
}

########################################################
## Check if we re-synthesis any of the IP cores
########################################################
BuildIpCores

########################################################
## Target Pre synthesis script
########################################################
source ${RUCKUS_DIR}/vivado_pre_synthesis.tcl

########################################################
## Synthesize
########################################################
if { [CheckSynth] != true } {
   ## Check for DCP only synthesis run
   if { [info exists ::env(SYNTH_DCP)] } {
      set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]
   }
   ## Launch the run
   launch_runs synth_1
   set src_rc [catch { 
      wait_on_run synth_1 
   } _RESULT]     
}

########################################################
## Force a refresh of project by close then open project
########################################################
VivadoRefresh ${VIVADO_PROJECT}

########################################################
## Check that the Synthesize is completed
########################################################
if { [CheckSynth printMsg] != true } {  
   close_project
   exit -1
}

########################################################
## Target post synthesis script
########################################################
source ${RUCKUS_DIR}/vivado_post_synthesis.tcl

########################################################
## Check if only doing Synthesize
########################################################
if { [info exists ::env(SYNTH_ONLY)] } {
   close_project
   GitBuildTag
   exit 0
}

########################################################
## Check if Synthesizen DCP Output
########################################################
if { [info exists ::env(SYNTH_DCP)] } {
   source ${RUCKUS_DIR}/vivado_dcp.tcl
   close_project
   GitBuildTag
   exit 0
}

########################################################
## Implement
########################################################
if { [CheckImpl] != true } {
   if { [file exists ${OUT_DIR}/IncrementalBuild.dcp] == 1 } {
      if { $::env(INCR_BUILD_BYPASS) != 0 } {
         set_property incremental_checkpoint ${OUT_DIR}/IncrementalBuild.dcp [get_runs impl_1]
      }
   }
   launch_runs -to_step write_bitstream impl_1
   set src_rc [catch { 
      wait_on_run impl_1 
   } _RESULT]     
}

########################################################
## Check that the Implement is completed
########################################################
if { [CheckImpl printMsg] != true } {
   close_project
   exit -1
}

########################################################
## Check if there were timing 
## or routing errors during implement
########################################################
if { [CheckTiming] != true } {
   close_project
   exit -1
}

########################################################
## Target post route script
########################################################
source ${RUCKUS_DIR}/vivado_post_route.tcl

########################################################
## Close the project and return sucessful flag
########################################################

close_project
exit 0
