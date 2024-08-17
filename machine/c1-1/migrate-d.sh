#! /usr/bin/env nix-shell
#! nix-shell -i bash --packages bash pv

set -e

REMOTE=d1

ssh -M root@${REMOTE} true

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
    SDATASET=$1
    TDATASET=${2:-${SDATASET}}
    zfs list ${TDATASET} || zfs create ${TDATASET}
    SMOUNT=$(ssh root@${REMOTE} zfs get mountpoint ${SDATASET} -o value -H)
    TMOUNT=$(zfs get mountpoint ${TDATASET} -o value -H)
    rsync -arPWx --delete root@${REMOTE}:${SMOUNT}/ ${TMOUNT}/
}

copy r/home
copy r/home/josh
copy r/home/josh/sync
copy d/photos
copy d/photos/Incoming
copy d/photos/Published
copy d/projects
copy d/software
copy d/backup
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
copy d/scratch/peer
copy d/scratch/usenet
copy d/varlib/images
copy d/media m/media

copy d/backup/timemachine

copy d/varlib/frigate-media

# copy d/varlib/frigate-config
