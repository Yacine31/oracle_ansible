#!/bin/sh
#-------------
# mise à jour de la balcklist de l'université de Toulouse
#-------------
# Historique
#-------------
# 31/07/2016 - YOU : création
#-------------

# récupération de la liste directement par rsync
rsync -arpogvt rsync://ftp.ut-capitole.fr/blacklist/dest/* /var/lib/squidguard/db/blacklists

# création des fichiers db pour quid
/usr/bin/squidGuard -C all

# modification du propriétaire des fichiers générés (et tous les autres)
chmod -R proxy:proxy /var/lib/squidguard/db

