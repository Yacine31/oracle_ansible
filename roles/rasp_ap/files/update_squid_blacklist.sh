#!/bin/bash -x
#-------------
# mise à jour de la balcklist de l'université de Toulouse
#-------------
# Historique
#-------------
# 31/07/2016 - YOU : création
#-------------

#------------------------------------------------------------------------------
# fonction d'affichage de la date ds les logs
#------------------------------------------------------------------------------
f_print()
{
        echo "[`date +"%Y/%m/%d %H:%M:%S"`] : $1" >> $LOG_FILE
} #f_print

#------------------------------------------------------------------------------
# definition des variables
#------------------------------------------------------------------------------
export SCRIPTS_DIR=/home/pi
export LOG_DIR=$SCRIPTS_DIR/logs
export DATE_JOUR=$(date +%Y.%m.%d-%H.%M)
export LOG_FILE=${LOG_DIR}/update_blacklist_tlse_${DATE_JOUR}.log

install -d ${LOG_DIR} -o pi -g pi

#------------------------------------------------------------------------------
# récupération de la liste directement par rsync
#------------------------------------------------------------------------------
f_print "----- Recuperation des nouvelles listes depuis le serveur de Toulouse -----"
rsync -arpvt rsync://ftp.ut-capitole.fr/blacklist/dest/* /var/lib/squidguard/db/blacklists >> $LOG_FILE

#------------------------------------------------------------------------------
# suppression des anciens fichiers db
#------------------------------------------------------------------------------
f_print "----- Suppression des anciens fichiers db -----"
find /var/lib/squidguard/db/blacklists -iname "*db" -exec rm -fv {} \;  >> $LOG_FILE 

#------------------------------------------------------------------------------
# création des fichiers db pour quid
#------------------------------------------------------------------------------
f_print "----- Creation des fichiers db par squidGuard -c all -----"
/usr/bin/squidGuard -C all >> $LOG_FILE 

#------------------------------------------------------------------------------
# modification du propriétaire des fichiers générés (et tous les autres)
#------------------------------------------------------------------------------
f_print "----- Modification des droits sur les fichiers db -----"
chown -Rv proxy:proxy /var/lib/squidguard/db/blacklists >> $LOG_FILE 

#------------------------------------------------------------------------------
# redémarrage de squid3
#------------------------------------------------------------------------------
f_print "----- Redémarrage de Squid -----"
systemctl restart squid3 >> $LOG_FILE 

#------------------------------------------------------------------------------
# Nettoyage auto des logs : durée de concervation de 15 jours
#------------------------------------------------------------------------------
f_print "----- Nettoyage des logs de plus de 15 jours -----"
find ${LOG_DIR} -type f -iname "*.log" -mtime +15 -exec rm -fv "{}" \; >> $LOG_FILE

f_print "----- Fin de la mise a jour de la blacklist -----"
