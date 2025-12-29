#! /usr/bin/env nix-shell
#! nix-shell -i bash -p sharutils

set -e

journalctl -fqn0 -u home-assistant.service | while read line
do
  date
  if [[ $line =~ "OSError: [Errno 24] No file descriptors available" ]]
  then
    TARGET="/storage/scratch/dump/journal-$(date +%Y%m%d-%H%M%S).txt"
    journalctl -u home-assistant.service >${TARGET} &
    systemctl restart home-assistant.service
    (echo "subject: Errno 24 in HA" && echo "HA restarted; see ${TARGET}") | msmtp "j@gustafson.me"
    wait
  fi
done
