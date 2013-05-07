#!/bin/bash

RET=$(pwd)
DIR="/root/scripts/deploiement"
WWW="/var/www/tools"

echo "Publication des mises à jours"
mv $WWW/*.tar.gz $WWW/archives/
mv $WWW/*.md5 $WWW/archives/

for TYPE in routeur client; do
  OLD="$(cut -d'-' -f2 $WWW/${TYPE}-version)"
  let NEW=$OLD+1
  echo "  Outils de $TYPE"
  cd $DIR/${TYPE}/files/scripts
  tar czf $WWW/$TYPE-${NEW}.tar.gz *
  echo "$TYPE-$NEW" > $WWW/$TYPE-version
  md5sum $WWW/$TYPE-${NEW}.tar.gz | cut -d" " -f1 > $WWW/$TYPE-${NEW}.md5
done

echo
echo "Terminé."
cd $RET
