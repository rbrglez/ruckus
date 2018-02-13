##############################################################################
## This file is part of 'SLAC Firmware Standard Library'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'SLAC Firmware Standard Library', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

# Get variables and Custom Procedures
source $::env(RUCKUS_DIR)/vivado_env_var.tcl

# Variables 
set PyRogueDirName  $::env(IMAGENAME).python
set ProjPythonDir   "${OUT_DIR}/${PyRogueDirName}"

# Remove old directory and files
exec rm -rf ${ProjPythonDir}
exec rm -rf ${IMAGES_DIR}/$::env(IMAGENAME).pyrogue.tar.gz

# Create a new directory
exec mkdir ${ProjPythonDir}
exec mkdir ${ProjPythonDir}/python

# Get the ruckus.tcl directory list
set dirList [read [open ${OUT_DIR}/dirList.txt]] 

# check for non-empty list
if { ${dirList} != "" } {
   # Loop through the list
   foreach dirPntr ${dirList} {
      # Check if python directory exist
      if { [file isdirectory ${dirPntr}/python/] == 1 } {
         # Create a list of files
         set fileList [glob -dir ${dirPntr}/python/ *]
         # check for non-empty list
         if { ${fileList} != "" } {
            # Loop through the list
            foreach filePntr ${fileList} {      
               # Copy all the files
               exec cp -rf ${filePntr} ${ProjPythonDir}/python/.
            }
         }
      }
   }
}

# Copy the licensing file
exec cp -f ${RUCKUS_DIR}/LICENSE.txt ${ProjPythonDir}/.

# Copy the build.info
if { $::env(GIT_HASH_LONG) != "" } {
   if { [file exists ${PROJ_DIR}/build.info] == 1 } {
      exec cp -f ${PROJ_DIR}/build.info ${ProjPythonDir}/.
   } 
} 

# Set the defaults directory
if { [info exists ::env(DEFAULTS_DIR)] != 1 } {
   set defaultsDir "$::env(PROJ_DIR)/config"
} else {
   set defaultsDir "$::env(DEFAULTS_DIR)"
}

# Copy the defaults into the dump directory
if { [file isdirectory ${defaultsDir}] == 1 } {
	exec cp -rf ${defaultsDir} ${ProjPythonDir}/.
} else {
	puts "Note: ${defaultsDir} doesn't exist"
}

# Compress the python directory to the target's image directory
exec tar -zcvf  ${IMAGES_DIR}/$::env(IMAGENAME).pyrogue.tar.gz -C ${OUT_DIR} ${PyRogueDirName}
exec cp -f      ${IMAGES_DIR}/$::env(IMAGENAME).pyrogue.tar.gz    $::env(IMPL_DIR)/$::env(IMAGENAME).pyrogue.bin
puts "${IMAGES_DIR}/$::env(IMAGENAME).pyrogue.tar.gz"
