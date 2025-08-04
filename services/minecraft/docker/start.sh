#!/bin/bash -e

if [ -f /home/minecraft/minecraft.pid ]
then
    echo "Already started!"
    exit 1
fi

cd "/home/minecraft"
mkdir -p config
cd config

echo "eula=true" > eula.txt

nohup ./run.sh >/home/minecraft/minecraft.log 2>&1 &
echo $! > "/home/minecraft/minecraft.pid"
