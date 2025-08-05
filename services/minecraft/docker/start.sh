#!/bin/bash -e

if [ -f /home/minecraft/minecraft.pid ]
then
    echo "Already started!"
    exit 1
fi

rm -f /home/minecraft/command_pipe
mkfifo /home/minecraft/command_pipe
nohup bash -c "while true; do sleep 86400; done" > ./command_pipe 2>&1 &
echo $! > "/home/minecraft/command_pipe.pid"

mkdir -p /home/minecraft/config
cd /home/minecraft/config

echo "eula=true" > eula.txt

nohup ./run.sh >/home/minecraft/minecraft.log < /home/minecraft/command_pipe 2>&1 &
echo $! > "/home/minecraft/minecraft.pid"
