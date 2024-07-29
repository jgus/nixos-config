#! /usr/bin/env nix-shell
#! nix-shell -i bash --packages bash pv

set -e

REMOTE=d1

NOW=$(date +%Y%m%d%H%M)

ssh -M root@${REMOTE} zfs snapshot -r d@migrate-${NOW}

repl() {
    DATASET=$1
    REMOTE_FIRST=$(ssh root@${REMOTE} zfs list -t snapshot ${DATASET} -o name -H | grep -v @clam | head -n 1)
    echo "Base is ${REMOTE_FIRST}"
    zfs list ${DATASET} || ssh root@${REMOTE} zfs send ${REMOTE_FIRST} | pv | zfs recv -F ${DATASET}
    LOCAL_LAST=$(zfs list -t snapshot ${DATASET} -o name -H | grep -v @clam | tail -n 1)
    REMOTE_LAST=$(ssh root@${REMOTE} zfs list -t snapshot ${DATASET} -o name -H | grep -v @clam | tail -n 1)
    echo "${LOCAL_LAST} -> ${REMOTE_LAST}"
    [[ "${LOCAL_LAST}" == "${REMOTE_LAST}" ]] || ssh root@${REMOTE} zfs send -I ${LOCAL_LAST} ${REMOTE_LAST} | pv | zfs recv -F ${DATASET}
}

copy() {
    DATASET=$1
    ssh root@${REMOTE} zfs destroy ${DATASET}@rsync || true
    ssh root@${REMOTE} zfs snapshot ${DATASET}@rsync
    zfs list ${DATASET} || zfs create ${DATASET}
    SMOUNT=$(ssh root@${REMOTE} zfs get mountpoint ${DATASET} -o value -H)
    TMOUNT=$(zfs get mountpoint ${DATASET} -o value -H)
    rsync -arP root@${REMOTE}:${SMOUNT}/.zfs/snapshot/rsync/ ${TMOUNT}/
    ssh root@${REMOTE} zfs destroy ${DATASET}@rsync
}

copy d/backup
copy d/backup/timemachine
copy d/external
copy d/external/brown
copy d/offsite
copy d/offsite/gustafson-nas
copy d/offsite/gustafson-nas/boot
copy d/offsite/gustafson-nas/d
copy d/offsite/gustafson-nas/d/Files
copy d/offsite/gustafson-nas/d/Movies
copy d/offsite/gustafson-nas/d/Music
copy d/offsite/gustafson-nas/d/Tv
copy d/offsite/gustafson-nas/d/plex
copy d/offsite/gustafson-nas/r
copy d/offsite/gustafson-nas/r/nixos
copy d/photos
copy d/photos/Incoming
copy d/photos/Published
copy d/projects
copy d/scratch/peer
copy d/scratch/usenet
copy d/software
copy d/varlib/images
copy d/media

repl d/varlib/frigate-config

copy d/varlib/frigate-media
