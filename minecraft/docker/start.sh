#!/bin/bash -e

if [ -f /home/minecraft/minecraft.pid ]
then
    echo "Already started!"
    exit 1
fi

cd "/home/minecraft"
mkdir -p config
cd config
if [ -f ./env ] ; then source ./env ; fi

PAPER_VER=${PAPER_VER:-1.17.1}
PAPER_BUILD=${PAPER_BUILD:-402}

[ -f paper-$PAPER_VER-$PAPER_BUILD.jar ] || wget https://papermc.io/api/v2/projects/paper/versions/$PAPER_VER/builds/$PAPER_BUILD/downloads/paper-$PAPER_VER-$PAPER_BUILD.jar

echo "eula=true" > eula.txt

nohup java -jar "./paper-$PAPER_VER-$PAPER_BUILD.jar" --nogui >/home/minecraft/minecraft.log 2>&1 &
echo $! > "/home/minecraft/minecraft.pid"
