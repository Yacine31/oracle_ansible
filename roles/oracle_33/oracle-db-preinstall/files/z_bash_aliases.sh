# aliases bash 
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias grep='grep --color=auto'
alias l.='ls -d .* --color=auto'
alias la='ls -latra'
alias ll='ls -ltrh'
alias ls='ls --color=auto'
alias tailf='tail -100f'
alias vi=vim

alias oh='cd $ORACLE_HOME'
alias tns='cd $ORACLE_HOME/network/admin'
alias list_instances='ps -ef | grep pmon | grep -v grep | cut -d_ -f3 | sort'