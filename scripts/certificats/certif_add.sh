#!/bin/bash

serveur=$1

if test "$serveur" == ""; then
  echo "Usage : $0 nom_du_serveur"
  exit 0
fi

echo "=================================="
echo "       Ajout d'un certificat"
echo "=================================="
echo

cd /root/certificats

if test -d $serveur; then
  echo "Erreur, certificat déjà créé pour ce serveur ! Abandon..."
  exit 0
fi

mkdir $serveur

cd $serveur


echo "Création de la clé pour $serveur"
openssl genrsa -des3 -out ${serveur}.key 1024
openssl rsa -in ${serveur}.key -out ${serveur}.key

echo
echo "Terminé !"

echo "Création du certificat de $serveur"
openssl req -new -key ${serveur}.key -out ${serveur}.csr

echo
echo "Terminé !"
echo

echo "Signature du certificat de $serveur"

openssl x509 -req -in ${serveur}.csr -out ${serveur}.crt -CA ../ca.crt -CAkey ../ca.key -CAcreateserial

echo
echo "Terminé !"
echo
echo "Certificat disponible ici : /root/certificats/${serveur}/${serveur}.crt"
echo "Clé disponible ici : /root/certificats/${serveur}/${serveur}.key"
echo
