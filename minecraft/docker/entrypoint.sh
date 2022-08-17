#!/bin/bash

sudo -u minecraft -i /usr/local/bin/start.sh

function cleanup()
{
    sudo -u minecraft -i /usr/local/bin/stop.sh
}
trap cleanup EXIT

mkdir -p /var/run/sshd
/usr/sbin/sshd -D -d -e
