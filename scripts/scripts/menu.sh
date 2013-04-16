#!/bin/bash
#
# Menu permettant l'accès aux fonctionnalités


# Variables
script_path="/root/scripts"

# Définitions des scripts
s_titre=(DNS_list DNS_add DNS_del Cert_list Cert_add Cert_Del Deploy)
s_desc=("Liste des enrgistrements DNS" "Ajouter un enregistrement DNS" "Supprimer un enregistrement DNS" "Liste des certificats" "Ajouter un certificat" "Supprimer un certificat" "Déployer une nouvelle machine")
s_url=(dns_list_hosts.sh dns_add_host.sh dns_del_host.sh certif_list.sh certif_add.sh certif_del.sh deploiement/deploy.sh)
s_arg=(non oui oui non oui oui oui)
s_nb=${#s_titre[*]}
let s_nb-=1
let nb_fin=s_nb+1

# Fonctions
# Gabarit :

#function print_list {
#  local retour=0
#  return $retour
#}

function print_list {
  local retour=0
  echo "========================================================="
  echo "Menu principal :" 
  for i in $(seq 0 $s_nb); do
    tput bold; tput setaf 4; echo -ne " ${i}"; tput sgr0
    echo -ne ". "
    tput bold; tput setaf 2; echo -ne "${s_titre[$i]}"; tput sgr0
    echo " - ${s_desc[$i]}"
  done
  tput bold; tput setaf 4; echo -ne " ${nb_fin}"; tput sgr0
  echo -ne ". "
  tput bold; tput setaf 2; echo -ne "Quitter"; tput sgr0
  echo " - Arrêt du programme, retour à la ligne de commande"
  echo "========================================================="
  echo
  return $retour
}

function exec_script {
  local retour=0
  local nb=$1
  if test $nb -eq $nb_fin; then echo "Au revoir !"; echo; exit 0; fi
  bash ${script_path}/${s_url[$nb]}
  if test "${s_arg[$nb]}" = "oui"; then
    echo "Indiquer les arguments :"
    echo -ne "  # ${s_url[$nb]} "
    read arguments
    bash ${script_path}/${s_url[$nb]} $arguments
  fi
  return $retour
}

function lecture {
  local retour=0
  echo -ne "Indiquer le numéro de l'action à exécuter : "
  read action
  if ! [[ "$action" =~ ^[0-9]+$ ]]; then
    let action=$nb_fin+100
  fi
  if test $action -le $nb_fin; then
    echo
    exec_script $action
  fi
  echo
  return $retour
}

clear
fin=0

while test 1; do
print_list
lecture
done
