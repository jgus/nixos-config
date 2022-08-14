#!/bin/sh

if [ -f /home/minecraft/minecraft.pid ]
then
    echo -n "Stopping.."
    PID=$(cat "/home/minecraft/minecraft.pid")
    (sleep 30; kill -9 ${PID} 2>/dev/null) &
    while kill ${PID} 2>/dev/null
    do
        echo -n "."
        sleep 1
    done
    echo
    rm /home/minecraft/minecraft.pid
fi
