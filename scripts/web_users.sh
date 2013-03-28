#!/bin/bash
#
#######################################
# Titre: Gestion des utilisateurs web #
#######################################
# Description : Permet de gérer les utilisateurs webs selon le
# fichier htpasswd $PASS_FILE.
#######################################
# Date : 13/09/2012
# Auteur: Alexandre Brianceau

PASS_FILE="/opt/trac.htpasswd"
USER=$2
PASS=$3

add() {
  return 0
}

del() {
  return 0

}

case "$1" in
  add)
   if [ "$PASS" != "" -a "$USER" != "" ]; then
     if [ "$(grep $USER $PASS_FILE)" == "" ]; then
       if htpasswd -b $PASS_FILE $USER $PASS; then
         echo "L'utilisateur $USER avec le mot de passe $PASS est créé !"
       fi
     else
       echo "L'utilisateur $USER existe déjà !"
     fi
   else
     echo "  Usage: ./$0 add \$USER \$PASS"
   fi
  ;;
  del)
   if [ "$USER" != "" ]; then
     if [ "$(grep $USER $PASS_FILE)" == "" ]; then
       echo "L'utilisateur $USER n'existe pas."
       exit 0
     else 
        if sed -i "/$USER/ d" $PASS_FILE; then
         echo "L'utilisateur $USER est supprimé !"
       else
         echo "Erreur lors de la suppression de $USER."
       fi
     fi
  else
    echo "  Usage: ./$0 del \$USER"
  fi
  ;;
  change)
   if [ "$PASS" != "" -a "$USER" != "" ]; then
     if [ "$(grep $USER $PASS_FILE)" != "" ]; then
       if htpasswd -b $PASS_FILE $USER $PASS; then
         echo "L'utilisateur $USER possède maintenant le mot de passe $PASS"
       fi
     else
       "L'utilisateur $USER n'existe pas !"
     fi
   else
     echo "  Usage: ./$0 change \$USER \$PASS"
   fi
  ;;
  list)
    cut -d":" -f1 $PASS_FILE
  ;;
  *)
    echo "  Usage: ./$0 add|change $USER $PASS"
    echo "         ./$0 del $USER"
    echo "         ./$0 list"
  ;;
esac
