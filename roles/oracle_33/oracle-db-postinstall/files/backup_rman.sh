#!/bin/sh
#------------------------------------------------------------------------------
# ORACLE DATABASE : BACKUP RMAN DB + AL
#------------------------------------------------------------------------------
# Historique :
#       14/09/2011 : YAO - Creation
#       12/10/2015 : YAO - adaptation à l'ensemble des bases
#       13/10/2015 : YAO - ajout des params en ligne de commande
#       03/05/2016 : YAO - adaptation a l'environnement SOM
#       04/05/2016 : YAO - ajout du niveau de sauvegarde : incrementale 0 ou 1
#       09/11/2022 : YAO - backup simple => db full
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# fonction init : c'est ici qu'il faut modifier toutes les variables liées
# à l'environnement
#------------------------------------------------------------------------------
f_init() {

        export ORACLE_OWNER=oracle

        # les différents répertoires
        export SCRIPTS_DIR=/home/oracle/scripts
        export BKP_LOG_DIR=$SCRIPTS_DIR/logs
        export BKP_LOCATION=/u04/rman/${ORACLE_SID}

        # nombre de sauvegarde RMAN en ligne à garder
        export BKP_REDUNDANCY=1
        export DATE_JOUR=$(date +%Y.%m.%d-%H.%M)
        export BKP_LOG_FILE=${BKP_LOG_DIR}/backup_rman_${ORACLE_SID}_${DATE_JOUR}.log
        export RMAN_CMD_FILE=${BKP_LOG_DIR}/rman_cmd_file_${ORACLE_SID}.rman

        # nombre de jours de conservation des logs de la sauvegarde
        export BKP_LOG_RETENTION=15

        # nombre de canaux à utiliser
        export PARALLELISM=1

        # mail pour envoyer les erreurs
        MAIL_RCPT="support@axiome.io,yacine.oumghar@gmail.com"

} # f_init

#------------------------------------------------------------------------------
# fonction d'aide
#------------------------------------------------------------------------------
f_help() {

        cat <<CATEOF
syntax : $O -s ORACLE_SID

-s ORACLE_SID

CATEOF
exit $1

} #f_help

#------------------------------------------------------------------------------
# fonction d'affichage de la date ds les logs
#------------------------------------------------------------------------------
f_print()
{
        echo "[`date +"%Y/%m/%d %H:%M:%S"`] : $1" >> $BKP_LOG_FILE
} #f_print

#------------------------------------------------------------------------------
# fonction de traitement des options de la ligne de commande
#------------------------------------------------------------------------------
f_options() {

        case ${BKP_LEVEL} in
        "FULL")
                        BKP_FULL=TRUE;
        ;;
        "INCR")
                        BKP_FULL=FALSE;
        ;;
        *) f_help 2;
        ;;
        esac

} #f_options


#----------------------------------------
#------------ MAIN ----------------------
#----------------------------------------

# s, l et t suivis des : => argument attendu
# h => pas d'argument attendu
while getopts s:h o
do
        case $o in
        s) ORACLE_SID=$OPTARG;
        ;;
        h) f_help 0;
        ;;
        *) f_help 2;
        ;;
        esac
done

#------------------------------------------------------------------------------
# traitement de la ligne de commande
#------------------------------------------------------------------------------

[ "${ORACLE_SID}" ] || f_help 2;

# f_options

# positionner les variables d'environnement ORACLE
export ORACLE_SID
ORAENV_ASK=NO
PATH=/usr/local/bin:$PATH
. oraenv -s >/dev/null

#------------------------------------------------------------------------------
# inititalisation des variables d'environnement
#------------------------------------------------------------------------------
f_init

#------------------------------------------------------------------------------
# si ce n'est pas le user oracle qui lance le script, on quitte
#------------------------------------------------------------------------------
if (test `whoami` != $ORACLE_OWNER)
then
        echo
        echo "-----------------------------------------------------"
        echo "Vous devez etre $ORACLE_OWNER pour lancer ce script"
        echo "-----------------------------------------------------"
        exit 2
fi

#------------------------------------------------------------------------------
# initialisation des chemins, s'ils n'existent pas ils seront créés par la commande install
#------------------------------------------------------------------------------
install -d ${BKP_LOCATION}
install -d ${BKP_LOG_DIR}

#------------------------------------------------------------------------------
# génération du script de la sauvegarde RMAN
#------------------------------------------------------------------------------
echo "
run {
CONFIGURE DEVICE TYPE DISK PARALLELISM $PARALLELISM ;
CONFIGURE RETENTION POLICY TO REDUNDANCY ${BKP_REDUNDANCY};
BACKUP DEVICE TYPE DISK FORMAT '${BKP_LOCATION}/data_%T_%t_%s_%p' TAG 'DATA_${DATE_JOUR}' AS COMPRESSED BACKUPSET DATABASE;
SQL 'ALTER SYSTEM ARCHIVE LOG CURRENT';
BACKUP DEVICE TYPE DISK FORMAT '${BKP_LOCATION}/arch_%T_%t_%s_%p' TAG 'ARCH_${DATE_JOUR}' AS COMPRESSED BACKUPSET ARCHIVELOG ALL DELETE ALL INPUT;
BACKUP CURRENT CONTROLFILE FORMAT '${BKP_LOCATION}/control_%T_%t_%s_%p' TAG 'CTLFILE_${DATE_JOUR}';
DELETE NOPROMPT OBSOLETE;
DELETE NOPROMPT EXPIRED BACKUPSET;
SQL \"ALTER DATABASE BACKUP CONTROLFILE TO TRACE AS ''${BKP_LOCATION}/${ORACLE_SID}_control_file.trc'' REUSE\";
SQL \"CREATE PFILE=''${BKP_LOCATION}/pfile_${ORACLE_SID}.ora'' FROM SPFILE\";
}
" > ${RMAN_CMD_FILE}

#------------------------------------------------------------------------------
# Execution du script RMAN
#------------------------------------------------------------------------------
f_print "------------------------- DEBUT DE LA BACKUP -------------------------"
${ORACLE_HOME}/bin/rman target / cmdfile=${RMAN_CMD_FILE} log=${BKP_LOG_FILE}

#------------------------------------------------------------------------------
# Mail si des erreurs dans le fichier de sauvegarde
#------------------------------------------------------------------------------
ERR_COUNT=$(egrep "^RMAN-[0-9]*|^ORA-[0-9]:" ${BKP_LOG_FILE} | wc -l)
SUBJECT="$(hostname)-${ORACLE_SID} : RMAN Backup"

if [ ${ERR_COUNT} -ne 0 ]; then
        mutt -s $SUBJECT ${MAIL_RCPT} < ${BKP_LOG_FILE}
else
        mutt -s $SUBJECT ${MAIL_RCPT} < ${BKP_LOG_FILE}
fi

#------------------------------------------------------------------------------
# Nettoyage auto des logs : durée de concervation déterminée par la variable : ${BKP_LOG_RETENTION}
#------------------------------------------------------------------------------
f_print "------------------------- NETTOYAGE DES LOGS -------------------------"
find ${BKP_LOG_DIR} -type f -iname "backup_rman_${BKP_TYPE}*.log" -mtime +${BKP_LOG_RETENTION} -exec rm -fv "{}" \; >> $BKP_LOG_FILE

f_print "------------------------- BACKUP ${BKP_TYPE} TERMINE -------------------------"
