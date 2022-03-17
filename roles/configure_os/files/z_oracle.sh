#!/bin/bash


## On entre seulement pour certains utilisateurs.
if [ $USER = "grid" ] || [ $USER = "oracle" ] || [ $USER = "root" ] ; then
    
    # Certaines operations ne sont pas a realiser pour root
    # les limites sont laissees par defaut
    # ainsi que le masque de creation de fichier ou le stty break.
    if [ $USER != "root" ] ; then
        # ajustement des limites
        if [ $SHELL = "/bin/ksh" ] ; then
            ulimit -p 16384
            ulimit -n 65536
            ulimit -s 32768
        else
            ulimit -u 16384 -n 65536
        fi
        ulimit -Hs 32768
        ulimit -Ss 10240

        # Masque de création des fichiers    
        umask 022

        # export ORACLE_HOME et ORACLE_SID
        ORACLE_SID=$(ps -ef | grep pmon | egrep -v 'grep|ASM|APX' | cut -d_ -f3 | head -1)
        if [ -n "$ORACLE_SID" ]; then export ORACLE_SID; fi
        if [ -e "/etc/oraInst.loc" ]; then
            INV_LOC=$(cat /etc/oraInst.loc | grep inventory_loc | cut -d= -f2)
            if [ -e "${INV_LOC}/ContentsXML/inventory.xml" ]; then
                export ORACLE_HOME=$(cat ${INV_LOC}/ContentsXML/inventory.xml | grep "<HOME_LIST" -A1 | tail -1 | sed 's/.*LOC="//g' | cut -d'"' -f1)
                export PATH=$ORACLE_HOME/bin:$PATH
            fi
        fi


        # Alias RL Wrap si disponible
        if [ `type rlwrap 2>/dev/null | wc -l` -eq 1 ] ; then
            alias sqlplus="rlwrap sqlplus"
            alias rman="rlwrap rman"
            alias asmcmd="rlwrap asmcmd"
            alias adrci="rlwrap adrci"      
            alias dgmgrl="rlwrap dgmgrl"
        fi
    fi
        
    # Mise en place d'un prompt coloré
    fd=0
    # Shell interactif ou non ?
    # Aucun intérêt hors d'un terminal interactif
    if [[ $- = *i* ]]
    then
        rouge=$(tput setaf 1)
        vert=$(tput setaf 2)
        jaune=$(tput setaf 3)
        bleu=$(tput setaf 4)
        gras=$(tput bold)
        reset=$(tput sgr0)

        export PS1='[\[$jaune\]\u\[$reset\]@\[$vert\]\h\[$reset\] \[$rouge\]${TWO_TASK:-$ORACLE_SID}\[$reset\] \W]\$ '
        export NLS_DATE_FORMAT='YYYY-MM-DD HH24:MI:SS'
    fi
fi

