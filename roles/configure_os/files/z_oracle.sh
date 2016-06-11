## Fichier de configuration d'environnement Oracle
## Pour infrastructure cluster ou standalone.
## Versions testees: 12.1, 11.2 GI et SA, flex/normal
##
## 20140813   YOM   Correction de l'emplacement des journaux cluster vers ADR en 12c
## 20140813   YOM   Correction concernant la détection Restart en 12c (olsnodes réponds...)
## 20140820   YOM   Correction des alias crsstat et crsstati pour implémenter les variables ORA_CRS car elles ne doivent pas être laissées dans l'environnement
## 20141202   YOM   Correction du prompt par défaut
## 20141203   YOM   Suppression des alias crsstat et crsstati pour les transformer en scripts
## 20141204   YOM   Ajout de l'alias OH pour un « cd $ORACLE_HOME »
## 20150121   YOM   Test si le terminal est interractif pour éviter les erreurs TPUT en v7
## Activation des echo pour DEBUG si mis à 1
DEBUG=0

## Contexte
APP_CTX=z_oracle.sh
HOSTNAME_SIMPLE=`hostname -s`
## Shell interactif ou non ?
fd=0
if [[ $- = *i* ]]
then
  INTERACTIF=OUI
else
  INTERACTIF=NON
fi

## Ajustement des limites (préconisations Oracle)
function ajustement_limites () {
    decho fonction ajustement limites
    if [ $SHELL = "/bin/ksh" ] ; then
        ulimit -p 16384		# pipe size
        ulimit -n 65536		# open files
        ulimit -s 32768		# stack size
    else
        ulimit -u 16384 -n 65536 -s 32768	# -u : max user processes
    fi
}

## Affichage des messages de sortie de debug
function decho () {
    if [ $DEBUG -eq 1 ] ; then
        echo $APP_CTX: $*
    fi
}

decho "Terminal en mode interactif: $INTERACTIF"

## On entre seulement pour certains utilisateurs.
## root een  fait partie pour la composante cluster, crsctl, ...
if [ $USER = "oracle" ] || [ $USER = "grid" ] || [ $USER = "root" ] ; then
    
     decho $USER login profile

     # Certaines operations ne sont pas a realiser pour root
     # les limites sont laissees par defaut
     # ainsi que le masque de creation de fichier ou le stty break.
    if [ $USER != "root" ] ; then
        ajustement_limites

        decho umask et stty break
        # Masque de création des fichiers    
        umask 022

        # Pour prévention SSH
        if [ -t 0 ]; then
            stty intr ^C
        fi
    fi

    # préparation pour l'inventaire
    # Si l'installation a ete realisee, on a un inventaire accessible que l'on peut traiter
    OLR_LOC=/etc/oracle/olr.loc
    ORA_INVENTORY_CFFILE=/etc/oraInst.loc
    decho OLR: $OLR_LOC
    decho Inventaire: $ORA_INVENTORY_CFFILE

    # Si l'installation n'est pas faite... on ignore cette partie
    if [ -f $ORA_INVENTORY_CFFILE ] ; then
        decho Installation trouvee
        # On recupere les informations de l'inventaire, pour traitement eventuel
        ORA_INVENTORY=`grep inventory_loc $ORA_INVENTORY_CFFILE | cut -d= -f2`
        ORA_INVENTORY_XMLFILE=$ORA_INVENTORY/ContentsXML/inventory.xml

        # Recuperation de l'emplacement du répertoire prive de l'utilisateur premier oracle
        ORA_USER_HOME=`egrep '^SED_PREMIER_COMPTE_ORACLE__:.*' /etc/passwd | cut -d: -f 6`
        ORA_EXPL_DIR=$ORA_USER_HOME/expl
        ORA_EXPL_BIN=$ORA_EXPL_DIR/bin
        ORA_EXPL_SQL=$ORA_EXPL_DIR/sql
        ORA_EXPL_TMP=$ORA_EXPL_DIR/tmp

        # Test pour savoir si GI installée
        if [ -f $OLR_LOC ] ; then
            decho GI installee
            # Mise en place du pointeur de racine CRS
            export ORA_CRS_HOME=`grep crs_home /etc/oracle/olr.loc|cut -d= -f2`
            decho ORA_CRS_HOME = $ORA_CRS_HOME

            # On utilise olsnodes qui "sors" rapidement pour aussi valider que la couche est UP
            # sinon on perds un temps phénoménal pour rien avec les timeout crsctl
            NODE_INFO=`$ORA_CRS_HOME/bin/olsnodes -l -n -a`
            if [ $? -ne 0 ] ; then
                # En cluster 11, on n'a pas de -a (mode cluster flex/normal)
                NODE_INFO=`$ORA_CRS_HOME/bin/olsnodes -l -n`
            fi

            
            if [ $? -eq 0 ] ; then
              # C'est UP, on peut traiter.  
                export ORA_CRS_NODE_NUM=`echo $NODE_INFO | awk '{print $2}'`
                export ORA_CRS_NODE_TYPE=`echo $NODE_INFO | awk '{print $3}'`
                decho ORA_CRS_NODE_NUM = $ORA_CRS_NODE_NUM
                decho ORA_CRS_NODE_TYPE = $ORA_CRS_NODE_TYPE
                export ORA_CRS_CLUSTER_NAME=`$ORA_CRS_HOME/bin/olsnodes -c`
                decho ORA_CRS_CLUSTER_NAME=$ORA_CRS_CLUSTER_NAME

                # Si le cluster n'a pas de nom, c'est que nous sommes en Oracle Restart. Donc pas de query activeversion!
                if [ "$ORA_CRS_CLUSTER_NAME" != "" ] ; then
                    export ORA_CRS_ACTIVEVERSION=`$ORA_CRS_HOME/bin/crsctl query crs activeversion | cut -d[ -f2 | cut -d. -f1`
                    if [ "$ORA_CRS_ACTIVEVERSION" -eq "12" ] ; then
                        # On peut attendre un cluster flex ou non
                        export ORA_CRS_CLUSTERMODE=`$ORA_CRS_HOME/bin/crsctl get cluster mode config |cut -d\" -f2`
                        # On raccourcis "standard" en "std" si besoin
                        if  [ "$ORA_CRS_CLUSTERMODE" = "standard" ] ; then
                            export ORA_CRS_CLUSTERMODE=std
                        fi
                    else
                        export ORA_CRS_CLUSTERMODE=std
                    fi
                else
                    ORA_CRS_CLUSTERMODE=rst
                fi    
                decho Mode: $ORA_CRS_CLUSTERMODE


            else
                decho Clusterware OFFLINE.
                # Est-on en RESTART ???!!!
                if [ `cat /etc/oracle/ocr.loc | grep "local_only=TRUE" |wc -l` -eq 1 ] ; then
                    decho certainement GI standalone pour RESTART
                    ORA_CRS_CLUSTERMODE=rst
                fi
            fi

            # Alias manipulation
            if [ $USER = "SED_ORACLE_TARGET__" ] ; then
                # pointeur facile pour crsctl...
                decho Alias crsctl cree
                alias crsctl='$ORA_CRS_HOME/bin/crsctl'
            elif [ $USER = "root" ] ; then
                    decho Ajustement path user root
                    # On ajoute le chemin du cluster dans le PATH 
                    export PATH=$ORA_CRS_HOME/bin:$ORA_USER_HOME/expl/bin:$PATH
            elif [ $USER = "SED_GRID_TARGET__" ] ; then
                decho environnement GI
                export ORACLE_HOME=$ORA_CRS_HOME
                export ORACLE_BASE=`$ORACLE_HOME/bin/orabase`
                export SQLPATH=$ORA_EXPL_SQL
                export PATH=$ORA_CRS_HOME/bin:$ORA_USER_HOME/expl/bin:$PATH
                if [ `ps -ef | grep -E 'pmon.*\+A' | grep -v grep | cut -d_ -f3- | wc -l` -gt 0 ] ; then
                    export ORACLE_SID=`ps -ef | grep -E 'pmon.*\+A' | grep -v grep | cut -d_ -f3- | sort | tail -1`
                fi
            fi
            ## Accès direct aux logs
            if [ "$INTERACTIF" = "OUI" ] ; then
                DRT_LI=`tput lines`
            else
                DRT_LI=100
            fi
            ## On teste la présence de fichiers "11" hors ADR.
            if [ -r $ORA_CRS_HOME/log/$HOSTNAME_SIMPLE/ohasd/ohasd.log ] ; then
                ## Configuration ancienne
                OHASD_LOG=$ORA_CRS_HOME/log/$HOSTNAME_SIMPLE/ohasd/ohasd.log
                CSSD_LOG=$ORA_CRS_HOME/log/$HOSTNAME_SIMPLE/cssd/ocssd.log
                CRSD_LOG=$ORA_CRS_HOME/log/$HOSTNAME_SIMPLE/crsd/crsd.log
                ALERT_LOG=$ORA_CRS_HOME/log/$HOSTNAME_SIMPLE/alert$HOSTNAME_SIMPLE.log
            else
                ## Configuration nouvelle ADR pour les journaux cluster
                OB=`ORACLE_HOME=$ORA_CRS_HOME ${ORA_CRS_HOME}/bin/orabase`
                OHASD_LOG=$OB/diag/crs/$HOSTNAME_SIMPLE/crs/trace/ohasd.trc
                CSSD_LOG=$OB/diag/crs/$HOSTNAME_SIMPLE/crs/trace/ocssd.trc
                CRSD_LOG=$OB/diag/crs/$HOSTNAME_SIMPLE/crs/trace/crsd.trc
                ALERT_LOG=$OB/diag/crs/$HOSTNAME_SIMPLE/crs/trace/alert.log
            fi
            ## Cluster Alert log
            alias alertgen="tail -${DRT_LI}f $ALERT_LOG"
            ## LOG - OHASD
            alias ohasd="tail -${DRT_LI}f $OHASD_LOG"
            ## LOG - CSSD
            alias cssd="tail -${DRT_LI}f $CSSD_LOG"
            ## LOG - CRSD
            alias crsd="tail -${DRT_LI}f $CRSD_LOG"
            ## Alert global watch
            
            ## Aucun intérêt dans un terminal non interactif
            if [ "$INTERACTIF" = "OUI" ] ; then
                DRT_LI=`expr $DRT_LI / 10 - 1`
                DRT_LI2=`expr $DRT_LI \* 3`
                DRT_LI6=`expr $DRT_LI \* 6`
                NORMAL=$(tput sgr0)
                ROUGE=$(tput setaf 1)
                alias alert="while :; do   clear ;  echo -e \"${ROUGE}ALERT********${NORMAL}\" ;   tail -$DRT_LI $ALERT_LOG ;   echo -e \"${ROUGE}CRSD*********${NORMAL}\" ;   tail -$DRT_LI2 $CRSD_LOG ;   echo -e \"${ROUGE}OCSSD********${NORMAL}\" ;   tail -$DRT_LI6 $CSSD_LOG ;   echo -e \"${ROUGE}OHASD********${NORMAL}\" ;   tail -$DRT_LI $OHASD_LOG ;   sleep 1; done"
            fi
        else
            decho GI non installee
            ORA_CRS_CLUSTERMODE=sa
        fi

        # Env oracle avec ou hors GI
        if [ $USER = "oracle" ] ; then
          export SQLPATH=$ORA_EXPL_SQL
          # Si 1 seul OH dans l'inventaire, on set. Non déterminable si GI non cluster (manque le CRS=true pour identifier)
            if [ `grep '<HOME NAME' $ORA_INVENTORY_XMLFILE | grep -v 'CRS' | grep -v "${ORA_CRS_HOME:-xxxxxxxxxx}" | wc -l` -eq 1 ] ; then
                export ORACLE_HOME=`grep '<HOME NAME' $ORA_INVENTORY_XMLFILE | grep -v 'CRS' | grep -v "${ORA_CRS_HOME:-xxxxxxxxxx}" | sed -e 's/.*LOC=//g' | cut -d'"' -f2`
                export ORACLE_BASE=`$ORACLE_HOME/bin/orabase`
                if [ "$ORACLE_HOME" = "$ORA_CRS_HOME" ] ; then
                    # Installation en suspens
                    unset ORACLE_HOME ORACLE_BASE
                else
                    export PATH=$ORACLE_HOME/bin:$ORA_USER_HOME/expl/bin:$PATH
                    decho ORACLE_HOME=$ORACLE_HOME
                    # On va essayer de se positionner dans l'environnement de la première base dispo.
                    DB_TARGET=`cat /etc/oratab | grep -Ev '^$|^#' | grep $ORACLE_HOME | cut -d: -f1 | head -1`
                    decho DB_TARGET=$DB_TARGET
                    if [ ! -z $DB_TARGET ] ; then
                        # DB trouvée, on cherche l'instance
                        if [ "$ORA_CRS_CLUSTERMODE" = "sa" ] ; then
                            # Si c'est une install SA, on teste sans ID d'instance
                            decho SA
                            DEC_INST=`ps -ef | grep -E "pmon_${DB_TARGET}$" | grep -v grep | cut -d_ -f3-`
                        else
                            # Sinon, sans complément, on vois
                            decho CL
                            DEC_INST=`ps -ef | grep -E "pmon_${DB_TARGET}(\_*[0-9]|[0-9]|$)" | grep -v grep | cut -d_ -f3-`
                        fi
                        decho $DEC_INST
                        if [ ! -z $DEC_INST ] ; then
                            export ORACLE_SID=$DEC_INST
                        fi
                    fi
                fi
            fi
        fi


        # Ajout d'un alias pour aller dans l'OH
        alias oh='cd $ORACLE_HOME'
    else
        decho NON INSTALLE
    fi
    # Mise en place d'un prompt sympa
    # Aucun intérêt hors d'un terminal interactif
    if [ "$INTERACTIF" = "OUI" ] ; then
        vert=$(tput setaf 2)
        bleu=$(tput setaf 4)
        jaune=$(tput setaf 3)
        gras=$(tput bold)
        rouge=$(tput setaf 1)
        reset=$(tput sgr0)
    fi

    decho prompt set
    if [ "$ORA_CRS_CLUSTERMODE" = "flex" ] ; then
        export PS1='[\[$jaune\]\u\[$reset\]@\[$vert\]\h\[$reset\] ($ORA_CRS_CLUSTERMODE $ORA_CRS_CLUSTER_NAME $ORA_CRS_NODE_TYPE:$ORA_CRS_NODE_NUM) \[$rouge\]${TWO_TASK:-$ORACLE_SID}\[$reset\] \W]\$ '
    elif [ "$ORA_CRS_CLUSTERMODE" = "std" ] ; then
        export PS1='[\[$jaune\]\u\[$reset\]@\[$vert\]\h\[$reset\] ($ORA_CRS_CLUSTERMODE $ORA_CRS_CLUSTER_NAME:$ORA_CRS_NODE_NUM) \[$rouge\]${TWO_TASK:-$ORACLE_SID}\[$reset\] \W]\$ '
    elif [ "$ORA_CRS_CLUSTERMODE" = "sa" -o "$ORA_CRS_CLUSTERMODE" = "rst" ] ; then
        export PS1='[\[$jaune\]\u\[$reset\]@\[$vert\]\h\[$reset\] ($ORA_CRS_CLUSTERMODE) \[$rouge\]${TWO_TASK:-$ORACLE_SID}\[$reset\] \W]\$ '
    else
        export PS1='[\[$jaune\]\u\[$reset\]@\[$vert\]\h\[$reset\] \[$rouge\]${TWO_TASK:-$ORACLE_SID}\[$reset\] \W]\$ '
    fi


    # Mode eMacs d'édition de ligne par défaut. Possible de passer en mode vi si nécessaire.
    set -o emacs

fi

unset ajustement_limites decho APP_CTX HOSTNAME_SIMPLE DEBUG OLR_LOC ORA_INVENTORY ORA_INVENTORY_XMLFILE ORA_INVENTORY_CFFILE ORA_USER_HOME ORA_EXPL_DIR ORA_EXPL_BIN ORA_EXPL_SQL ORA_EXPL_TMP DRT_LI DRT_LI2 DRT_LI6 NODE_INFO DB_TARGET DEC_INST ORA_CRS_HOME INTERACTIF


# Alias RL Wrap si disponible
if [ `/bin/rpm -qa |grep -i rlwrap | wc -l` -eq 1 ] ; then
   alias sqlplus='rlwrap sqlplus'
   alias rman='rlwrap rman'
   alias asmcmd='rlwrap asmcmd'
   alias adrci='rlwrap adrci'      
   alias dgmgrl='rlwrap dgmgrl'
fi

# alias pour le shell Bash
alias grep='grep --color=auto'
alias vi=vim

