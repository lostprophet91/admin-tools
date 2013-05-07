#!/bin/bash

###########################################################
# Execution BASH library
#
# Version 1.0
# Libraries required: lib-log.sh lib-print.sh
# Functions implemented :
#    EXECUTE "command" : Execute a command, and print the result
###########################################################

# List of libraries needed
LIB_NEEDED="print log"

function EXECUTE() {
  # Template : EXECUTE "command" "description"

  local RET=0
  local DATE="$(date +%F" "%H:%M:%S)"
  local OUT_EXEC="/tmp/exec_out_fil.$(date +%s).${RANDOM}.log"

  # Print the description, or the command if there is not
  if [[ -z $2 ]]; then
    PRINT "$1 : ";
  else PRINT "$2 : "
  fi

  # Execute the command
  $1 &> $OUT_EXEC
  RET=$?

  if [[ $RET -eq 0 ]]; then
    PRINT "OK\n" "green"
  else
    PRINT "FAILED\n" "red"
    while read line           
      do           
        PRINT "\t> $line\n" "blue"
    done <$OUT_EXEC
  fi

  LOG "$DATE" "$RET" "$2 [[$1]]"

  rm $OUT_EXEC

  return $RET

}

