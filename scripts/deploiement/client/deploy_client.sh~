#!/bin/bash

serveur=$1
nom_serveur=$2
adresse=$3

if [[ "$(hostname)" = "" ]]; then
  netmasque="$(ifconfig eth0 | grep "inet " | cut -d":" -f4 | cut -d" " -f1)"
else
  netmasque="$(ifconfig eth1 | grep "inet " | cut -d":" -f4 | cut -d" " -f1)"
fi

domaine="$(grep "zone \"" /etc/bind/named.conf.local | head -n1 | cut -d"\"" -f2)"
client="$(cat /root/nom_client)"

dir="/root/scripts/deploiement/client"
script_dns_add=/root/scripts/dns_add_host.sh

# Couleurs :
C_RED=$(tput setaf 1)
C_GREEN=$(tput setaf 2)
C_NORMAL=$(tput sgr0)

if [[ "$serveur" = "" ]]; then
  echo "  Usage : $0 adresse_du_serveur_actuel [nom_du_serveur] [adresse_voulue_pour_le_serveur]"
  exit 0
fi

LOG_FOLDER=/var/log/deploiements
LOG_FILE="${LOG_FOLDER}/$(date +%F)_${serveur}"

function afficher() {
  # Gabarit : afficher "ma commande" "Mon message"
  local retour=0
  local LARGEUR=$(tput cols)

  let LARGEUR-=${#2}
  echo "$(date +%F" "%H:%M:%S ) -> $2" >> $LOG_FILE
  
  echo -ne "$2"

  if $1 &>>$LOG_FILE; then
    retour=$?
    let LARGEUR+=2
    printf '%*s%s%s\n' $LARGEUR "[$C_GREEN" "OK" "${C_NORMAL}]"
  else
    retour=$?
    let LARGEUR-=2
    printf '%*s%s%s\n' $LARGEUR "[$C_RED" "ERREUR" "${C_NORMAL}]"
  fi

  return $retour
  }

function ajouter(){
  # Rajoute une ligne dans un fichier
  # Gabarit : ajouter "Ma ligne de mots" "/le/fichier" "Mon message"
  local retour=0
  ssh $serveur "echo -e \"$1\" >> $2"
  retour=$?
  return $retour
}

function executer(){
  # Exécute une commande
  # Gabarit : executer "Ma commande" "Mon message"
  local retour=0
  afficher "ssh $serveur $1" "$2"
  retour=$?
  return $retour
}

function copier(){
  # Copie des fichiers
  # Gabarit : copier "fichier1 fichier2" "/la/destination" "Mon message"
  local retour=0
  afficher "scp $1 ${serveur}:$2" "$3"
  retour=$?
  if ! [[ retour -eq 0 ]]; then
    afficher "scp $1 ${serveur}:$2" "$3 (nouvelle tentative)"
  fi
  retour=$?
  return $retour
}

function installer(){
  # Installer des logiciels selon la distribution
  # Gabarit : installer "paquet1 paquet2" "Mon message"
  local retour=0
  case $distrib in
    "debian")
    afficher "ssh $serveur apt-get install -y $1" "$2"
    retour=$?
      ;;
    "redhat")
    afficher "ssh $serveur yum install -y $1" "$2"
    retour=$?
      ;;
    *)
    retour=5
      ;;
  esac
  return $retour
}

function detection_distribution() {
  # Définitions des fichiers d'identifications
  local f_deb=/etc/debian_version
  local f_rhel=/etc/redhat-release
  
  if ssh $serveur "[[ -f $f_deb ]]";then 
    distrib="debian"
    version="$(ssh $serveur cat $f_deb)"
  elif ssh $serveur "[[ -f $f_rhel ]]";then 
    distrib="redhat"
    version="$(ssh $serveur cat $f_rhel)"
  else
    return 1
  fi

  echo "  Environnement détecté : $distrib ($version)"

  return 0
}

function reseau_valide() {
  # Test la validité des informations fournies à propos du réseau
  local retour=1
  local msg="Erreur inconnue."
  if [[ "$(echo $nom_serveur | egrep "^([a-z]|[0-9]|\-)+")" = "" ]]; then
    msg="Erreur sur le nom du client."
  elif [[ "$(echo $serveur | egrep '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')" = "" ]]; then
    msg="Adresse IP du serveur non valide."
  elif [[ "$(echo $adresse | egrep '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')" = "" ]]; then
    msg="Adresse IP du serveur non valide."
  elif nc -z -w 1 $adresse 22; then
    msg="L'adresse existe déjà quelque part."
  else
    retour=0
  fi

  if [[ $retour -eq 1 ]] ; then echo "${C_RED}${msg}${C_NORMAL}"; echo $msg >> $LOG_FILE; fi
  return $retour
}

function traitement_reseau() {

while ! reseau_valide ; do
  echo "Choisir l'adresse IP du serveur (ex: 192.168.1.34) :"
  echo -ne "  > "
  read serveur

  echo "Choisir le nom du serveur (ex: mon-beau-serveur) :"
  echo -ne "  > "
  read nom_serveur
done

}

function test_ret() {
  # Test le retour d'une exécution et stoppe en cas de besoin
  # Gabarit : test_ret $?
  if ! [[ $1 -eq 0 ]] ; then
    echo "Abandon du script..."
    exit $1
  fi
  }

if test "$(whoami | grep root)" == ""; then
  echo "Vous devez être root !!! Abandon..."
  exit 0
fi


if ! [[ -d $LOG_FOLDER ]] ; then
  mkdir $LOG_FOLDER
fi

echo "=========================================================="
echo "     Assistance au déploiement d'une nouvelle machine"
echo "=========================================================="
echo

echo "$(date +%F" "%H:%M:%S ) ==> Début de déploiement" >> $LOG_FILE



# ============================================================
traitement_reseau
nom_routeur="${client}-$nom_serveur"
# Vérification de présence dans le DNS ou ajout en cas de besoin
if [[ "$(bash /root/scripts/dns/dns_list_hosts.sh ${nom_client} | grep $serveur | grep -v Scope)" = "" ]]; then 
  adresse_lan=""
  afficher "bash /root/scripts/dns/dns_add_host.sh $nom_client $serveur" "Ajout de $nom_client (IP:$serveur) dans le DNS"
  test_ret $?
fi

echo "Mise en oeuvre du SSH :"
afficher "nc -z $serveur 22" "  Test d'accès au serveur en SSH"
test_ret $?

copier "-r /root/.ssh" "/root/" "  Mise en place des liaisons SSH"
test_ret $?

if [[ "$(ssh $serveur md5sum /etc/motd | cut -d' ' -f1)" = "$(md5sum ${dir}/files/motd | cut -d' ' -f1)" ]]; then
  echo "Abandon, le serveur distant ($serveur) est déjà paramétré"
  exit 1
fi



# ============================================================
echo "Adaptation de l'environnement :"

# Test de détection de la distribution
afficher detection_distribution "  Détection de l'environnement"

if ! [[ $? -eq 0 ]]; then
  ret_manu_distrib=1
  liste_distrib="debian redhat"
  while ! [[ $ret_manu_distrib -eq 0 ]]; do
    echo -ne "Erreur: Le type de ditribution du serveur n'a pas été trouvé, veuiller l'indiquer manuellement ($liste_distrib) : "
    read distrib
    for i in $liste_distrib; do
      if [[ $distrib = $i ]]; then 
        ret_manu_distrib=0
      fi
    done
  done
else
  # Execution réelle pour avoir les variables
  detection_distribution
fi

ajouter "export http_proxy=\\\"192.168.1.1:3128\\\"" "/root/.bashrc" "  Préparation du proxy web pour \"root\""

ajouter "alias ll='ls -l'" "/root/.bashrc" "  Ajout des alias pour l'utilisateur \"root\""

copier "${dir}/files/motd" "/etc/motd" "  Copie du message d'accueil (motd)"

copier "${dir}/files/motd_perso_client" "/etc/motd_perso" "  Copie du message d'accueil au premier demarrage (motd_perso)"

ajouter "if test -f /var/log/first_run; then cat /etc/motd_perso; fi; rm -f /var/log/first_run\n" "/root/.bashrc" "  Ajout du script de message d'accueil au premier démarrage"

# Scripts
copier "-r ${dir}/files/scripts" "/root/" "  Copie des scripts"




# ============================================================
echo "Configuration du gestionnaire de paquets :"
case $distrib in
  "debian")
    if [[ "$(echo $version | grep 6)" != "" ]]; then
      copier "${dir}/files/sources.list.debian6" "/etc/apt/sources.list" "  Mise à jour de la liste des dépôts"
      ajouter 'Acquire::http::Proxy \"http://192.168.1.1:3128\";' "/etc/apt/apt.conf.d/proxy" "  Configuration du proxy pour le gestionnaire de paquets"
      executer "apt-get update" "  Mise à jour de la liste des paquets"
    fi
    ;;
  "redhat")
      ssh $serveur rm /etc/yum.repos.d/* &> $LOG_FILE
      copier "${dir}/files/routeur.repo" "/etc/yum.repos.d/" "  Mise à jour de la liste des dépôts"
    ;;
esac



# ============================================================
echo "Installation des outils d'exploitations :"

# NTP
installer "ntp" "  Installation du serveur de temps"
la_date="$(date +%D" "%H:%M:%S)"
executer "date -s \"$la_date\"" "    Mise à l'heure du serveur ($la_date)"
copier "${dir}/files/ntp.conf" "/etc/ntp.conf" "    Paramétrage du serveur de temps"
executer "/etc/init.d/ntp restart" "    Relance du serveur de temps"


installer "vim" "  Installation de VIM"

copier "${dir}/files/.vimrc" "/root/" "    Configuration de VIM"



# ============================================================
echo "Configuration du réseau :"

case $distrib in
  "debian")
    # Configuration du réseau strict
    executer "echo $nom_routeur > /etc/hostname; /etc/init.d/hostname.sh" "  Modification du nom en $nom_routeur"
#    ajouter "\n# Reseau interne du client $client :\n\
#allow-hotplug eth0\n\
#iface eth0 inet static\n\
#  address ${adresse}\n\
#  netmask ${netmasque}\n" "/etc/network/interfaces" "  Configuration de la carte interne eth0"

    ;;
  "redhat")
    ;;
esac
retour_bind=$?


# DHCP
mac_ad="$(ssh $serveur /sbin/ifconfig | grep 'eth0' | tr -s ' ' | cut -d ' ' -f5)"
if [[ "$(grep $mac_ad /etc/dhcp/dhcpd.conf)" = "" ]]; then
  echo -e "\n host $nom_routeur {\n\
  hardware ethernet $mac_ad;\n\
  fixed-address $adresse;\n\
}\n" >> /etc/dhcp/dhcpd.conf
  afficher "/etc/init.d/isc-dhcp-server restart" "  Ajout d'une reservation de l'adresse $serveur dans le DHCP"
fi



# ============================================================
echo "Installation des outils d'exploitations :"

# VIM
installer "vim" "  Installation de VIM"
if [[ $? -eq 0 ]]; then 
  copier "${dir}/files/.vimrc" "/root/" "  Configuration de VIM"
fi

#ajouter "domaine=\"$domaine\"\ndir_zones=\"$d_zones\"\n" "/root/scripts/dns/domaine" "  Configuration des scripts"
#ajouter "alias dns_add='sh /root/scripts/dns/dns_add_host.sh'\n\
#alias dns_del='sh /root/scripts/dns/dns_del_host.sh'\n\
#alias dns_list='sh /root/scripts/dns/dns_list_hosts.sh'\n\
#alias service='sh /etc/init.d/'\n" "/root/.bashrc" "  Ajout des alias de scripts pour \"root\""



# ============================================================
echo "Ultime configuration :"

echo -ne "Reconfiguration du réseau, veuillez attendre"
ssh -o "ConnectTimeout 1" -o "ConnectionAttempts 1" $serveur "ifdown eth0 &>/dev/null; sleep 2; ifup eth0" & echo "."

while [[ "$(ping -c1 $adresse | grep "1 received")" = "" ]]; do sleep 1;echo -ne "."; done

afficher "echo OK" "  Relance de la carte eth0 ($adresse)"
sleep 1
serveur="$adresse"
executer "touch /var/log/first_run" "  Activation du premier démarrage"

# ============================================================
echo
echo "Terminé !"
