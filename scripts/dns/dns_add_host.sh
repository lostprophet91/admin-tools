#!/bin/sh
host_name=$1
host_dest=$2
zone_file="/var/lib/bind/bcs.bull.net.hosts"

if test "$(whoami | grep "root")" = ""; then echo "Vous devez être root"; exit; fi

if test "$host_name" = "" -o "$host_dest" = ""; then
  echo "Usage: $0 host dest"
  echo "Example: $0 my_server.hey.you 127.0.0.1"
  echo "     or: $0 my_server.hey.you yes.its.me"
  exit 1
fi

if test "$(echo $host_name | grep ".bcs.bull.net")" = ""; then
  host_name=$host_name".bcs.bull.net"
fi

if test "$(echo $host_dest | egrep '([[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}')" = ""; then
  if test "$(echo $host_dest | grep ".bcs.bull.net")" = ""; then
    host_dest=$host_dest".bcs.bull.net"
  fi
  echo -n "Ajout d'un CNAME : "
  ajout="$host_name.\tIN\tCNAME\t$host_dest.\n"
  printf "$ajout"
else
  echo -n "Ajout d'un A : "
  ajout="$host_name.\tIN\tA\t$host_dest\n"
  printf "$ajout\n"
fi

if test "$(grep "$host_name" $zone_file | grep "${host_dest}$")" = ""; then
  echo "  --> Enregistrement de $host_name OK !"
  printf "$ajout\n" >> $zone_file
  /etc/init.d/bind9 reload 1>/dev/null
else
  echo "  --> L'enregistrement de $host_name existe déjà !"
fi

