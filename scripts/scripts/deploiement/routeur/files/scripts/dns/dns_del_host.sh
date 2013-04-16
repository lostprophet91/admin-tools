#!/bin/sh
host_name=$1
host_dest=$2
dir="/root/scripts/dns"
. /root/scripts/dns/domaine
dir_zones="/var/lib/bind"
zone_file="${dir_zones}/${domaine}.hosts"

### Test si ROOT

if test "$(whoami | grep "root")" = ""; then echo "Vous devez être root"; exit; fi

### Test si le script est correctement lancé

if test "$host_name" = ""; then
  echo "Usage: $0 host dest"
  echo "Example: $0 my_server.hey.you 127.0.0.1"
  echo "     or: $0 my_server.hey.you yes.its.me"
  exit 1
fi

### Vérification de la définition de la destination

if test "$host_dest" = ""; then
  liste=$(. ${dir}/dns_list_hosts.sh | grep -v "Scope" | grep "$host_name")
  if [ "$liste" = "" ]; then
    echo "Aucune entrée trouvée correspondant à \"$host_name\". Abandon."
    exit 0
  fi
  echo "Liste des entrées de $host_name :"
  . ${dir}/dns_list_hosts.sh | grep -v "Scope" | grep "$host_name"
  echo "Etes-vous sûr de supprimer toutes les entrées correspondant à \"$host_name\" ? (y/n)"
  read result
  if [ "$result" = "y" ]; then
    host_dest=""
  elif [ "$result" = "n" ]; then
    echo "Abandon."
    exit 0
  else
    . $0
    exit 0
  fi
fi

### Normalisation du nom

if test "$(echo $host_name | grep ".${domaine}")" = ""; then
  host_name=$host_name".${domaine}"
fi

if test "$(echo $host_dest | egrep '([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}')" = ""; then
  if test "$(echo $host_dest | grep ".${domaine}")" = ""; then
    host_dest=$host_dest".${domaine}"
  fi
fi

### Suppression

nb_ligne=$(grep -n "$host_name" $zone_file | grep "$host_dest" | cut -d":" -f1) 

if test "$nb_ligne" = ""; then
  echo "  --> Enregistrement de $host_name non trouvé !"
else
  for nb in $nb_ligne; do
nb_ligne_one=$(grep -n "$host_name" $zone_file | grep "$host_dest" | cut -d":" -f1| head -n1) 
    sed -i ${nb_ligne_one}d $zone_file
    echo "  --> Enregistrement supprimé ! (ligne $nb)"
  done
  /etc/init.d/bind9 reload 1>/dev/null
fi

