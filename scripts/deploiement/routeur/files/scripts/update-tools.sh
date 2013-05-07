#!/bin/bash

SERVER="$1"
DIR="/root/scripts"

echo "====================================="
echo "       Mise à jour des outils"
echo "====================================="
echo

V_LOC="$(cut -d'-' -f2 ${DIR}/routeur-version)"
V_DIST="$(wget -qO- http://$1/tools/routeur-version |cut -d'-' -f2)"
echo "Version actuelle : $V_LOC"
echo "Version du serveur : $V_DIST"

if [[ $V_LOC -lt $V_DIST ]]; then
  wget -P /tmp http://$1/tools/$V_DIST.tar.gz
  if [[ "$(md5sum /tmp/routeur-$V_DIST.tar.gz | cut -d" " -f1)" == "$(wget -qO- http://$1/tools/routeur-$V_DIST.md5)" ]] ; then
    rm -Rf $DIR/*
    cd $DIR
    tar xzf /tmp/routeur-$V_DIST.tar.gz
  else echo "Echec lors du téléchargement de la dernière version !"; exit
  fi
fi

echo "Outils mis à jours !"
