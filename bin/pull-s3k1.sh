#!/usr/bin/env -S bash -e

LOCK=/tmp/sync-to-cloud.lock

if [ -f ${LOCK} ]
then
    echo "Already in progress"
    exit 0
fi
touch ${LOCK}

function onexit {
    rm ${LOCK}
}
trap onexit EXIT

zfs_cmd () {
    if [[ "$1" == "" ]]
    then
        echo "zfs"
    else
        echo "ssh $1 zfs"
    fi
}

zfs_list_snapshots () {
    $(zfs_cmd $1) list -H -t snapshot -o name | grep -v @znap_.\*_frequent | grep -v @znap_.\*_hourly | grep -v @clam || true
}

zfs_has_snapshot () {
    local DATASET=$1 ; shift
    local SNAPSHOT=$1 ; shift
    [[ ( "${SNAPSHOT}" == "" ) ]] && return 1
    for EXISTING in "$@"
    do
        [[ "${EXISTING}" == "${DATASET}@${SNAPSHOT}" ]] && return 0
    done
    return 1
}

zfs_send_new_snapshots() {
    local SOURCE_HOST=$1
    local SOURCE_DATASET=$2
    local TARGET_HOST=$3
    local TARGET_DATASET=$4

    local SOURCE_SNAPSHOTS_FULL
    local TARGET_SNAPSHOTS_FULL
    echo "Listing source snapshots from ${SOURCE_DATASET}..."
    SOURCE_SNAPSHOTS_FULL=($(zfs_list_snapshots "${SOURCE_HOST}" | grep ^${SOURCE_DATASET}@ || true))
    echo "Listing target snapshots from ${TARGET_DATASET}..."
    TARGET_SNAPSHOTS_FULL=($(zfs_list_snapshots "${TARGET_HOST}" | grep ^${TARGET_DATASET}@ || true))

    echo "Processing snapshots..."
    local INCREMENTAL=""
    for SNAPSHOT_FULL in "${SOURCE_SNAPSHOTS_FULL[@]}"
    do
        SNAPSHOT=${SNAPSHOT_FULL#${SOURCE_DATASET}@}
        if zfs_has_snapshot "${TARGET_DATASET}" "${SNAPSHOT}" "${TARGET_SNAPSHOTS_FULL[@]}"
        then
            echo "Skipping snapshot ${SNAPSHOT}"
        else
            echo "Sending snapshot (${SOURCE_HOST})${SOURCE_DATASET}@${SNAPSHOT} -> (${TARGET_HOST})${TARGET_DATASET}"
            echo "$(zfs_cmd "${SOURCE_HOST}") send -v ${INCREMENTAL} ${SOURCE_DATASET}@${SNAPSHOT} | $(zfs_cmd "${TARGET_HOST}") receive -F ${TARGET_DATASET}"
            $(zfs_cmd "${SOURCE_HOST}") send -v ${INCREMENTAL} ${SOURCE_DATASET}@${SNAPSHOT} | $(zfs_cmd "${TARGET_HOST}") receive -F ${TARGET_DATASET}
        fi
        INCREMENTAL="-i ${SOURCE_DATASET}@${SNAPSHOT}"
    done

    echo "Done sending ${SOURCE_DATASET}"
}

for x in media photos software
do
    rsync -arP --delete root@s3k1:/d/${x}/ /d/${x}/
done

DATASETS=(d/backup d/external d/external/brown d/home d/home/josh d/home/josh/.cache d/home/josh/sync d/projects d/scratch d/scratch/peer d/varlib d/varlib/docker d/varlib/sonarr d/varlib/syncthing d/varlib/transmission)
for f in $(ssh root@s3k1 zfs list -H -o name -t filesystem -r d/offsite)
do
    DATASETS+=(${f})
done

for x in "${DATASETS[@]}"
do
    zfs_send_new_snapshots root@s3k1 ${x} "" ${x}
done
