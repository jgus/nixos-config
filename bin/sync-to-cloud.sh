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

zfs_list_snapshots () {
    zfs list -H -t snapshot -o name | grep -v @clam || true
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

zfs_rclone_backup() {
    local SOURCE_DATASET=$1

    local SOURCE_SNAPSHOTS_FULL
    local TARGET_SNAPSHOTS_FULL
    echo "Listing source snapshots from ${SOURCE_DATASET}..."
    SOURCE_SNAPSHOTS_FULL=($(zfs_list_snapshots "${SOURCE_HOST}" | grep ^${SOURCE_DATASET}@ || true))
    echo "Listing target snapshots from ${SOURCE_DATASET}..."
    TARGET_SNAPSHOTS_FULL=($(rclone --config /etc/nixos/.secrets/rclone.conf lsf backup-archive:${SOURCE_DATASET}/_/ | sed 's/~.*$//' | awk "{ print \"${SOURCE_DATASET}@\" \$1 }" || true))

    echo "Processing snapshots..."
    local INCREMENTAL=""
    local INCREMENTAL_RCLONE=""
    for SNAPSHOT_FULL in "${SOURCE_SNAPSHOTS_FULL[@]}"
    do
        SNAPSHOT=${SNAPSHOT_FULL#${SOURCE_DATASET}@}
        if zfs_has_snapshot "${SOURCE_DATASET}" "${SNAPSHOT}" "${TARGET_SNAPSHOTS_FULL[@]}"
        then
            echo "Skipping snapshot ${SNAPSHOT}"
        else
            echo "Sending snapshot ${SOURCE_DATASET}@${SNAPSHOT}"
            echo "zfs send -v ${INCREMENTAL} ${SOURCE_DATASET}@${SNAPSHOT} | rclone --config /etc/nixos/.secrets/rclone.conf rcat backup-archive:${SOURCE_DATASET}/_/${SNAPSHOT}${INCREMENTAL_RCLONE}"
            zfs send -v ${INCREMENTAL} ${SOURCE_DATASET}@${SNAPSHOT} | rclone --config /etc/nixos/.secrets/rclone.conf rcat backup-archive:${SOURCE_DATASET}/_/${SNAPSHOT}${INCREMENTAL_RCLONE}
        fi
        INCREMENTAL="-i ${SOURCE_DATASET}@${SNAPSHOT}"
        INCREMENTAL_RCLONE="~${SNAPSHOT}"
    done

    echo "Done sending ${SOURCE_DATASET}"
}

zfs_rclone_restore() {
    local SOURCE_DATASET=$1
    local SNAPSHOT=$2
    local TARGET_DATASET=$3

    if zfs list ${TARGET_DATASET}@${SNAPSHOT} >/dev/null 2>&1
    then
        echo "${TARGET_DATASET}@${SNAPSHOT} exists"
        return 0
    fi

    local SOURCE_SNAPSHOT
    SOURCE_SNAPSHOTS=($(rclone --config /etc/nixos/.secrets/rclone.conf lsf backup-archive:${SOURCE_DATASET}/_/ | grep "^${SNAPSHOT}" || true))

    if (( ${#SOURCE_SNAPSHOTS[@]} == 0 ))
    then
        echo "Couldn't find ${SOURCE_DATASET}@${SNAPSHOT}"
        return 1
    fi

    local SOURCE_SNAPSHOT=${SOURCE_SNAPSHOTS[0]}

    if [[ "${SOURCE_SNAPSHOT}" =~ .*\~.* ]]
    then
        local BASE=${SOURCE_SNAPSHOT##*~}
        echo "Need ${BASE} first"
        zfs_rclone_restore ${SOURCE_DATASET} ${BASE} ${TARGET_DATASET}
    fi

    echo "Restoring ${SOURCE_SNAPSHOT}"
    rclone --config /etc/nixos/.secrets/rclone.conf cat backup-archive:${SOURCE_DATASET}/_/${SOURCE_SNAPSHOT} | zfs receive -F ${TARGET_DATASET}
}


DATASETS=()
DIRECTORIES=()
for f in $(zfs list -H -o name -t filesystem)
do
    [[ "$(zfs get -H -o value autobackup:cloud-$(hostname) ${f})" == "true" ]] || continue
    [[ "$(zfs get -H -o value canmount ${f})" != "off" ]] || continue
    DATASETS+=(${f})
done

for x in "${DATASETS[@]}"
do
    # zfs_rclone_backup ${x}
    zfs destroy ${x}@cloud >/dev/null 2>&1 || true
    zfs snapshot ${x}@cloud
    DIRECTORIES+=("$(zfs get -H -o value mountpoint ${x})/.zfs/snapshot/cloud")
done

# DIRECTORIES+=(/d/backup)
for x in "${DIRECTORIES[@]}"
do
    echo "##########"
    echo "Pushing directory ${x%/.zfs/snapshot/cloud}"
    echo "##########"
    rclone --config /etc/nixos/.secrets/rclone.conf sync -v "${x}" "backup-archive:sync/$(hostname)/${x%/.zfs/snapshot/cloud}/_"
done

# zfs_rclone_restore bpool znap_2022-05-15-0900_daily d/scratch/bpool-test
