#!/bin/sh

sudo -u minecraft -i /usr/local/bin/start.sh
mkdir -p /var/run/sshd
/usr/sbin/sshd -D -e
