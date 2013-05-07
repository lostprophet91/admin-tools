#!/bin/bash

SERVER="$1"
DIR="/root/scripts"

echo "====================================="
echo "       Mise à jour des outils"
echo "====================================="
echo

V_LOC="$(cat ${DIR}/version)"
V_DIST="$(wget -qO- http://$1/tools/version)"
echo "Version actuelle : $V_LOC"
echo "Version du serveur : $V_DIST"

if [[ $V_LOC != $V_DIST ]]; then
  wget -P /tmp http://$1/tools/$V_DIST.tar.gz
  if [[ "$(md5sum /tmp/$V_DIST.tar.gz | cut -d" " -f1)" == "$(wget -qO- http://$1/tools/$V_DIST.md5)" ]] ; then
    rm -Rf $DIR/*
    cd $DIR
    tar xzf /tmp/$V_DIST.tar.gz
  else echo "Echec lors du téléchargement de la dernière version !"; exit
  fi
fi

echo
echo "Outils mis à jours !"
