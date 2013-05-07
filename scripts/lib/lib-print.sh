#!/bin/bash

###########################################################
# Printing BASH library
#
# Version 1.0
# Libraries required: lib-log.sh
# Functions implemented :
#    PRINT "message" "color" : Print message and log it
#    EXECUTE "command" : Execute a command, and print the result
###########################################################

# List of libraries needed
LIB_NEEDED="log"

function PRINT() {
  # Template : PRINT "message" "color"

  local COLOR=7

  case "$2" in
    red) COLOR=1;;
    yellow) COLOR=3;;
    pink) COLOR=5;;
    blue) COLOR=4;;
    green) COLOR=2;;
    *) ;;
  esac

  # Set the color :
  tput setaf $COLOR
  
  # Print the message :
  echo -ne "$1"

  # Return to the normal color :
  tput sgr0
  
}
