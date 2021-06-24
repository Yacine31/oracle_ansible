# Alias RL Wrap si disponible
if [ `/bin/rpm -qa |grep -i rlwrap | wc -l` -eq 1 ] ; then
   alias sqlplus='rlwrap sqlplus'
   alias rman='rlwrap rman'
   alias asmcmd='rlwrap asmcmd'
   alias adrci='rlwrap adrci'      
   alias dgmgrl='rlwrap dgmgrl'
fi

# aliases bash 
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias grep='grep --color=auto'
alias l.='ls -d .* --color=auto'
alias la='ls -latra'
alias ll='ls -ltrh'
alias ls='ls --color=auto'
alias oh='cd $ORACLE_HOME'
alias tailf='tail -100f'
alias tns='cd $ORACLE_HOME/network/admin'
alias vi=vim
