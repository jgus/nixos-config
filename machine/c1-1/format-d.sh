#!/usr/bin/env -S bash -e

COUNT=28
ZPOOL_TYPE=raidz3

ZPOOL_OPTS=(
    -o ashift=12
    -O acltype=posixacl
    -O aclinherit=passthrough
    -O compression=lz4
    -O dnodesize=auto
    -O normalization=formD
    -O relatime=on
    -O xattr=sa
    -O mountpoint=/d
    -O encryption=on
    -O keyformat=raw
    -O keylocation=file:///boot/.secrets/vkey
    -O recordsize=4M
    -O autobackup:snap-$(hostname)=true
)

AVAILABLE_DISKS=($(for i in {0..22} {24..28}; do echo /dev/disk/by-path/pci-0000\:0d\:00.0-scsi-0\:0\:${i}\:0; done))
DISKS=($(for i in $(seq 0 $((COUNT-1))); do echo ${AVAILABLE_DISKS[${i}]}; done))

zpool create -f "${ZPOOL_OPTS[@]}" d ${ZPOOL_TYPE} "${DISKS[@]}"

zfs create -o autobackup:snap-$(hostname)=false -o recordsize=1M d/scratch
zfs create -o recordsize=1M d/external
zfs create -o recordsize=1M d/offsite
zfs create -o recordsize=2M d/photos
zfs create -o recordsize=2M d/projects
zfs create -o mountpoint=/var/lib -o canmount=off d/varlib
