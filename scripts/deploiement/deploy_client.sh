#!/bin/bash

serveur=$1
client=$2
domaine=$3
adresse=$4
masque=$5
dir="/root/scripts/deploiement"
script_dns_add=/root/scripts/dns_add_host.sh

# Couleurs :
C_RED=$(tput setaf 1)
C_GREEN=$(tput setaf 2)
C_NORMAL=$(tput sgr0)

if [[ "$serveur" = "" ]]; then
  echo "  Usage : $0 adresse_du_serveur [nom_du_client] [zone_dns_client] [sous-réseau] [masque]"
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
  if [[ "$(echo $client | egrep "^([a-z]|[0-9]|\-)+")" = "" ]]; then
    msg="Erreur sur le nom du client."
  elif [[ "$(echo $domaine | egrep "^([a-z]|[0-9]|\-)+")" = "" ]]; then
    msg="Erreur sur le domaine."
  elif [[ "$(dig NS $domaine | grep ANSWER | cut -d, -f2 | grep "ANSWER: 0")" = "" ]]; then
    msg="Le domaine existe déjà quelque part."
  elif [[ "$(echo $serveur | egrep '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')" = "" ]]; then
    msg="Adresse IP du serveur non valide."
  elif [[ "$(echo $adresse | egrep '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')" = "" ]]; then
    msg="Adresse IP du sous-réseau non valide."
  elif nc -z -w 1 $adresse 22; then
    msg="L'adresse existe déjà quelque part."
  elif [[ "$(echo $masque | egrep "^(8|16|24)+")" = "" ]]; then
    msg="Le masque n'est pas valide (/8, 16 ou 24 seulement)."
  else
    retour=0
  fi

  if [[ $retour -eq 1 ]] ; then echo "${C_RED}${msg}${C_NORMAL}"; echo $msg >> $LOG_FILE; fi
  return $retour
}

function adresse_inverse() {
  adresse_inv=$(echo $1 | cut -d. -f4) 
  adresse_inv="${adresse_inv}.$(echo $1 | cut -d. -f3)"
  adresse_inv="${adresse_inv}.$(echo $1 | cut -d. -f2)"
  adresse_inv="${adresse_inv}.$(echo $1 | cut -d. -f1)"
}

function traitement_reseau() {

while ! reseau_valide ; do
  echo "Choisir l'adresse IP du serveur (ex: 192.168.1.34) :"
  echo -ne "  > "
  read serveur

  echo "Choisir le nom du client (ex: bull) :"
  echo -ne "  > "
  read client

  echo "Choisir le domaine du sous-routeur (ex: bull.net) : "
  echo -ne "  ${client}-routeur."
  read domaine

  echo "Choisir son adresse IP de sous-réseau (ex: 192.168.34.254) :"
  echo -ne "  > "
  read adresse

  echo "Choisir son masque de sous-réseau (ex: 255.255.255.0) :"
  echo -ne "  > "
  read masque
done

adresse_inverse $adresse

local nb_coupe=0
local post_ad_masque=0
local deb=0
local end=0

case $masque in
  "8")
    nb_coupe="1"
    netmasque="255.0.0.0"
    post_ad_masque="0.0.0"
    deb="1.1.1" ;end="254.254.254"
    ;;
  "16")
    nb_coupe="1,2"
    netmasque="255.255.0.0"
    post_ad_masque="0.0"
    deb="1.1" ;end="254.254"
    ;;
  "24")
    nb_coupe="1,2,3"
    netmasque="255.255.255.0"
    post_ad_masque="0"
    deb="1" ;end="254"
    ;;
esac
domaine_inv="$(echo $adresse_inv | cut -d. -f${nb_coupe}).in-addr.arpa"
adresse_netmasque="$(echo $adresse | cut -d. -f${nb_coupe}).$post_ad_masque"
range_deb="$(echo $adresse | cut -d. -f${nb_coupe}).$deb"
range_end="$(echo $adresse | cut -d. -f${nb_coupe}).$end"

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
nom_routeur="${client}-routeur"
# Vérification de présence dans le DNS ou ajout en cas de besoin
if [[ "$(bash /root/scripts/dns/dns_list_hosts.sh ${nom_routeur} | grep $serveur | grep -v Scope)" = "" ]]; then 
  adresse_lan=""
  afficher "bash /root/scripts/dns/dns_add_host.sh $nom_routeur $serveur" "Ajout de $nom_routeur (IP:$serveur) dans le DNS"
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
copier "-r ${dir}/files/scripts_client" "/root/" "  Copie des scripts"




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
    ajouter "\n# Reseau interne du client $client :\n\
allow-hotplug eth1
iface eth1 inet static
  address ${adresse}
  netmask ${netmasque}\n" "/etc/network/interfaces" "  Configuration de la carte interne eth1"
    executer "ifup eth1" "    Montage de la carte eth1 ($adresse)"

    # Installation du serveur DNS
    installer "bind9 bind9-doc" "  Installation du serveur DNS"
    d_named="/etc/bind"
    f_named_conf="${d_named}/named.conf"
    f_named_conf_local="${d_named}/named.conf.local"
    d_zones="/var/lib/bind"
    ;;
  "redhat")
    installer "named" "  Installation du serveur DNS"
    ;;
esac
retour_bind=$?

# Copie du script de routage et execution
copier "${dir}/files/scripts/init/routeur" "/etc/init.d/routeur" "  Copie du script d'init du routage"
#executer "mkdir -p /root/scripts/reseau/" "    Création du dossier du script de routage"
#copier "${dir}/files/scripts/init/script_routeur.sh" "/root/scripts/reseau/script_routeur.sh" "  Copie du script de routage"
case $distrib in
  "debian")
    executer "update-rc.d routeur defaults" "    Execution automatique du script au démarrage"
  ;;
  "redhat")
    executer "chkconfig routeur on" "    Execution automatique du script au démarrage"
  ;;
esac
executer "chmod ug+x /etc/init.d/routeur; /etc/init.d/routeur start" "    Activation du mode routeur"

if [[ "$(grep "$adresse_netmasque netmask $netmasque gw $serveur" /root/scripts/route_vers_sous_reseaux.sh)" = "" ]]  ; then
  echo "route add -net $adresse_netmasque netmask $netmasque gw $serveur" >> /root/scripts/route_vers_sous_reseaux.sh
fi
afficher "sh /root/scripts/route_vers_sous_reseaux.sh" "    Activation du routage vers le sous-reseau $adresse_netmasque"

# DHCP
mac_ad="$(ssh $serveur /sbin/ifconfig | grep 'eth0' | tr -s ' ' | cut -d ' ' -f5)"
if [[ "$(grep $mac_ad /etc/dhcp/dhcpd.conf)" = "" ]]; then
  echo -e "\n host $nom_routeur {\n\
  hardware ethernet $mac_ad;\n\
  fixed-address $serveur;\n\
}\n" >> /etc/dhcp/dhcpd.conf
  afficher "/etc/init.d/isc-dhcp-server restart" "  Ajout d'une reservation de l'adresse $serveur dans le DHCP"
fi

installer "isc-dhcp-server" "  Installation du serveur DHCP"

if [[ $? -eq 0 ]]; then 
  sed -e "s/NETMASQUE/${netmasque}/g" -e "s/DOMAINE/${domaine}/g" -e "s/ADRESSE/${adresse}/g" -e "s/RANGE_DEB/${range_deb}/g" -e "s/RANGE_END/${range_end}/g"  -e "s/RESEAU/${adresse_netmasque}/g" < ${dir}/files/gabarit_dhcpd.conf > /tmp/$domaine.dhcpd.conf
  copier "/tmp/$domaine.dhcpd.conf" "/etc/dhcp/dhcpd.conf" "    Copie du paramétrage du serveur DHCP"
  rm /tmp/$domaine.dhcpd.conf
  executer "/etc/init.d/isc-dhcp-server restart" "    Relance du serveur DHCP"
fi


if [[ $retour_bind -eq 0 ]]; then 
  ajouter "include \\\"/etc/bind/rndc.key\\\";\n\
controls {\n\
  inet 127.0.0.1 allow { localhost; } keys { rndc-key; };\n\
};\n" "/etc/bind/named.conf" "    Autorisation de RNDC en local"

  ajouter "zone \\\"${domaine}\\\" {\n\
  type master;\n\
  file \\\"${d_zones}/$domaine.hosts\\\";\n\
};\n\
\n\
zone \\\"$domaine_inv\\\" {\n\
  type master;\n\
  file \\\"${d_zones}/${domaine}.inverse\\\";\n\
};\n" "${f_named_conf_local}" "   Ajout de la zone $domaine et son inverse $domaine_inv"

  # Préparation des zones
  sed -e "s/HOTE/${nom_routeur}/g" -e "s/DOMAINE/${domaine}/g" -e "s/ADRESSE/${adresse}/g" < ${dir}/files/gabarit_dns.hosts > /tmp/$domaine.hosts

  sed  -e "s/DOMAINE_INV/${domaine_inv}/g" -e "s/HOTE/${nom_routeur}/g" -e "s/DOMAINE/${domaine}/g" -e "s/ADRESSE/${adresse}/g" < ${dir}/files/gabarit_dns.inverse > /tmp/$domaine.inverse
  echo "Paramétrage du serveur DNS :"

  copier "/tmp/$domaine.hosts" "${d_zones}/" "    Copie du gabarit de zone"
  copier "/tmp/$domaine.inverse" "${d_zones}/" "    Copie du gabarit de zone inverse"

  # Suppression des fichiers temporaires
  rm -f /tmp/$domaine.hosts
  rm -f /tmp/$domaine.inverse

  copier "${dir}/files/named.conf.options" "${d_named}/named.conf.options" "    Copie des options BIND"

  executer "/etc/init.d/bind9 reload" "    Relance du serveur BIND"

  if test $? -eq 0 -a "$(grep $domaine /etc/bind/named.conf.local)" = "" ; then
    echo -e "\n # Zone de forward vers le routeur $nom_routeur (IP: $serveur) pour la zone $domaine \n\
zone \"${domaine}\" {\n\
        type forward;\n\
        forward only;\n\
        forwarders {${serveur};} ;\n\
};\n" >> /etc/bind/named.conf.local
    afficher "/etc/init.d/bind9 reload" "  Ajout du forward de la zone ${domaine}"
  fi

fi


# MAIL
case $distrib in
  "debian")
  #  installer "postfix dovecot-imapd" "  Installation du serveur mail"
    ;;
  "redhat")
   # installer "postfix dovecot" "  Installation du serveur mail"
    #executer "yum remove sendmail" "  Désinstallation du précédent serveur mail" 
    ;;
esac



# ============================================================
echo "Installation des outils d'exploitations :"

# VIM
installer "vim" "  Installation de VIM"
if [[ $? -eq 0 ]]; then 
  copier "${dir}/files/.vimrc" "/root/" "  Configuration de VIM"
fi

ajouter "domaine=\"$domaine\"\ndir_zones=\"$d_zones\"\n" "/root/scripts/dns/domaine" "  Configuration des scripts"
ajouter "alias dns_add='sh /root/scripts/dns/dns_add_host.sh'\n\
alias dns_del='sh /root/scripts/dns/dns_del_host.sh'\n\
alias dns_list='sh /root/scripts/dns/dns_list_hosts.sh'\n\
alias service='sh /etc/init.d/'\n" "/root/.bashrc" "  Ajout des alias de scripts pour \"root\""



# ============================================================
echo "Ultime configuration :"
executer "touch /var/log/first_run" "  Activation du premier démarrage"



# ============================================================
echo
echo "Terminé !"
