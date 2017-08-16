#!/bin/bash
#
#
# chkconfig: 35 98 08

### BEGIN INIT INFO
# Short-Description: start and stop db, oms and agent
# Description: start and stop db, oms and agent
### END INIT INFO

# Source function library.
. /etc/init.d/functions

prog=oracledb
lockfile=/var/lock/subsys/$prog

export ORACLE_HOME={{ db_home }}

start() {
        [ "$NETWORKING" = "no" ] && exit 1

        # Start daemons.
        echo -n $"Starting $prog: "

        # Start everything
        su - oracle -c "$ORACLE_HOME/bin/dbstart $ORACLE_HOME"

        RETVAL=$?
        echo
        [ $RETVAL -eq 0 ] && touch $lockfile
        return $RETVAL
}

stop() {
        [ "$EUID" != "0" ] && exit 4
        echo -n $"Shutting down $prog: "

        # stop everything
        su - oracle -c "$ORACLE_HOME/bin/dbshut $ORACLE_HOME"

        RETVAL=$?
        echo
        [ $RETVAL -eq 0 ] && rm -f $lockfile
        return $RETVAL
}

# See how we were called.
case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  restart)
        stop
        start
        ;;
  *)
        echo $"Usage: $0 {start|stop|restart}"
        exit 2
esac

