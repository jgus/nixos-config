#!/bin/sh

if [ -f /home/minecraft/minecraft.pid ]
then
    PID=$(</home/minecraft/minecraft.pid)
    echo -n "Stopping..."
    echo "stop" > /home/minecraft/command_pipe
    for i in {1..30}; do
        if ! kill -0 ${PID} 2>/dev/null
        then
            break
        fi
        echo -n "."
        sleep 1
    done
    if kill -0 ${PID} 2>/dev/null
    then
        echo
        echo "WARNING: Process not stopping normally; killing it!"
        kill -9 ${PID} 2>/dev/null
    fi
    echo
    rm /home/minecraft/minecraft.pid
else
    echo "Already stopped."
fi

if [ -f /home/minecraft/command_pipe.pid ]
then
    PID=$(</home/minecraft/command_pipe.pid)
    kill ${PID} 2>/dev/null
    rm /home/minecraft/command_pipe.pid
fi

rm -f /home/minecraft/command_pipe
