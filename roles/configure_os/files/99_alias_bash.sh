# Alias RL Wrap si disponible
if [ `/bin/rpm -qa |grep -i rlwrap | wc -l` -eq 1 ] ; then
   alias sqlplus='rlwrap sqlplus'
   alias rman='rlwrap rman'
   alias asmcmd='rlwrap asmcmd'
   alias adrci='rlwrap adrci'      
   alias dgmgrl='rlwrap dgmgrl'
fi

# autres alias Oracle 
alias oh='cd $ORACLE_HOM'
alias tns='cd $ORACLE_HOME/network/admin'

# alias pour le shell Bash
alias grep='grep --color=auto'
alias vi=vim
alias ll='ls -ltrh'
alias la='ls -latra'
alias tailf='tail -100f'

