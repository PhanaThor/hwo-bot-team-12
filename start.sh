#!/bin/bash

set -e

playername=$1
host=$2
port=$3
pidfile=.tmp/client.pid

usage() {
    echo "Usage: `basename $0` <playername> <serverhost> <serverport>"
    echo ""
    echo "Starts a coffeescript client against a server"
}

if [ -z "$port" ]; then
    usage >&2
    exit 1
fi

ensure_pid_file() {
    mkdir -p .tmp
    touch $pidfile
}

exit_if_running() {
    pid=`cat $pidfile`
    if kill -0 $pid 2>/dev/null; then
	echo "Client is already running (pid $pid)"
	exit 1
    fi
}

function start_client() {
    logfile=log/game.log
    (coffee src/client.coffee $playername $host $port &>>$logfile) & echo $! > $pidfile
    echo "Logging into $logfile"
}

ensure_pid_file
exit_if_running
start_client
