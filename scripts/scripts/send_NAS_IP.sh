#!/bin/bash

# Fichier temporaire
TMP="/opt/NAS_IP.txt"

# Serveur de mail :
MAILSERVER="msgc-004.bull.fr"
# Port :
PORT="25"
# Destinataires (a separer par un espace entre chaque adresse):
MAILTO="alexandre.brianceau@bull.net" # jean-louis.cunin@bull.net alain.marie@bull.net vincent.lemiere@bull.net"

function send_a_mail() {
  # send_a_mail envoi un mail d'information

    local IP_NAS=$1
    
    #Test d'acces au serveur mail :
    if nc -z $MAILSERVER $PORT; then
    
      exec 3<>/dev/tcp/$MAILSERVER/$PORT

      echo -en "HELO mail.email.com\r\n" >&3 
      echo -en "MAIL FROM:alexandre.brianceau@bull.net\r\n" >&3 
      # Envoi du mail a chaque destinataire :
      for MEL in $MAILTO; do
        echo -en "RCPT TO:$MEL\r\n" >&3
      done
      
      echo -en "DATA\r\n" >&3 
      echo -en "Subject: Adresse du NAS : $IP_NAS" >&3 

      echo -en "\r\n" >&3
      echo -en "Nouvelle adresse IP publique sur le reseau Bull du NAS : $IP_NAS\r\n" >&3

      echo -en "\r\n" >&3
      echo -en ".\r\n" >&3
      echo -en "QUIT\r\n" >&3

      cat <&3 1>/dev/null
    else 
      echo "Le serveur mail $MAILSERVER (port $PORT) est indisponible"
    fi
    
  }

if test ! -f $TMP; then touch $TMP; fi

IP_CALCUL=$(ssh root@192.168.1.254 ifconfig eth0 | grep "129" | cut -d":" -f 2 | cut -d " " -f1)

if test "$(grep $IP_CALCUL $TMP)" = ""; then
  send_a_mail "$IP_CALCUL"
  echo $IP_CALCUL > $TMP
  echo $IP_CALCUL
fi

