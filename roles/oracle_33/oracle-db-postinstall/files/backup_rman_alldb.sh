#!/bin/sh
#------------------------------------------------------------------------------
# ORACLE DATABASE : BACKUP ALL DB RMAN 
#------------------------------------------------------------------------------
# Historique :
#       21/04/2023 : YAO - Creation : backup de toutes les bases ouvertes
#------------------------------------------------------------------------------

# toutes les bases ouvertes sont sauvegardées par le script RMAN

for i in $(ps -ef | grep pmon | grep -v grep | cut -d_ -f3)
do 
	sh /home/oracle/scripts/backup_rman.sh -s $i
done
