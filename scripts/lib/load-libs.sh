#!/bin/bash

LIB_DIR="$1"
LIBS_TO_LOAD="$2"

echo "dir: $LIB_DIR"
echo "to_load: $LIBS_TO_LOAD"

libs_needed() {
  local FILE=$1
  
  local NEEDED=$(grep "LIB_NEEDED" $FILE | cut -d'"' -f 2)
  echo "Needed: $NEEDED"
  for elmt in $(echo $NEEDED); do
    if [[ "$(echo $LIBS_TO_LOAD | grep $elmt)" == "" ]]; then
      LIBS_TO_LOAD="$LIBS_TO_LOAD $elmt"
      echo "Adding lib $elmt in the loading process."
    else echo "Lib $elmt already in the loading process."
    fi
  done

  return 0
}

for lib in $(echo $LIBS_TO_LOAD); do
  if [[ -f ${LIB_DIR}/lib-${lib}.sh ]]; then
    libs_needed ${LIB_DIR}/lib-${lib}.sh
  else
    echo "Library $lib not exist."
    LIBS_TO_LOAD=$(echo $LIBS_TO_LOAD | grep -v $lib)
  fi
done

for lib in $(echo $LIBS_TO_LOAD); do
  .  ${LIB_DIR}/lib-${lib}.sh
  echo "Library $lib loaded."
done

