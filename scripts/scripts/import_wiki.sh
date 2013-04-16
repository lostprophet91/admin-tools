#!/bin/bash
echo ""
echo "============================================"
echo "              Import du WIKI"
echo "============================================"

echo
echo -n "Import des données du wiki..."
if scp -r nas:/raid/data/htdocs/wiki/* /var/www/wiki/ &>/dev/null; then echo OK; else echo Erreur; fi
echo -n "Import de la base de données SQLITE du wiki..."
if scp -r nas:/raid/data/htdocs/sqlite/ /var/www/wiki/ &>/dev/null; then echo OK; else echo Erreur; fi
echo -n "Adaptation du wiki au nouvel hôte..."
if sed -e "s/raid0\/data\/htdocs/var\/www\/wiki/g" -e "s/129.181.20.21:88/routeur.bcs.bull.net/g" /var/www/wiki/LocalSettings.php > /var/www/wiki/LocalSettings.php ; then echo OK; else echo Erreur; fi
echo
echo "Terminé.
