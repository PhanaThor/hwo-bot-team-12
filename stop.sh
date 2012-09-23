#!/bin/bash

pidfile=.tmp/client.pid

if [ -e "$pidfile" ]; then
    pid=`cat $pidfile`
    kill $pid 2>/dev/null
    rm $pidfile
    echo "Stopped the client"
else
    echo "No client running"
fi
