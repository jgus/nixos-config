#!/usr/bin/env -S bash -e

ZPOOL_OPTS=(
    -o ashift=12
    -O acltype=posixacl
    -O aclinherit=passthrough
    -O compression=lz4
    -O dnodesize=auto
    -O normalization=formD
    -O relatime=on
    -O xattr=sa
    -O encryption=on
    -O keyformat=raw
    -O keylocation=file:///boot/vkey
    -O recordsize=1M
    -O autobackup:snap-$(hostname)=true
)

D_DISKS=(
    /dev/disk/by-id/scsi-35000cca26a2e4448
    /dev/disk/by-id/scsi-35000cca26a2f6f58
    /dev/disk/by-id/scsi-35000cca26a35ff6c
    /dev/disk/by-id/scsi-35000cca26a409bd4
    /dev/disk/by-id/scsi-35000cca26a945b64
    /dev/disk/by-id/scsi-35000cca26a97f720
    /dev/disk/by-id/scsi-35000cca26a992310
    /dev/disk/by-id/scsi-35000cca26a9975e8
    /dev/disk/by-id/scsi-35000cca26a9e21f8
    /dev/disk/by-id/scsi-35000cca26a9e7150
    /dev/disk/by-id/scsi-35000cca26a9f8e74
)

M_DISKS=(
    /dev/disk/by-id/scsi-35000cca26a9871e4
    /dev/disk/by-id/scsi-35000cca26a35e998
    /dev/disk/by-id/scsi-35000cca26a40a444
    /dev/disk/by-id/scsi-35000cca26a34b108
    /dev/disk/by-id/scsi-35000cca26a9e20f4
    /dev/disk/by-id/scsi-35000cca26a361d9c
    /dev/disk/by-id/scsi-35000cca26a3f8ad0
    /dev/disk/by-id/scsi-35000cca26aa07e54
    /dev/disk/by-id/scsi-35000cca26a988188
    /dev/disk/by-id/scsi-35000cca26a993418
    /dev/disk/by-id/scsi-35000cca26a9add94
    /dev/disk/by-id/scsi-35000cca26a926508
    /dev/disk/by-id/scsi-35000cca26aa0d918
    /dev/disk/by-id/scsi-35000cca26a9f3cd0
    /dev/disk/by-id/scsi-35000cca26a99fce8
    /dev/disk/by-id/scsi-35000cca26a9fb548
    /dev/disk/by-id/scsi-35000cca26aa02478
    /dev/disk/by-id/scsi-35000cca26a347a70
)

zpool create -f "${ZPOOL_OPTS[@]}" -O mountpoint=/d d raidz3 "${D_DISKS[@]}"

zfs create -o autobackup:snap-$(hostname)=false d/scratch
zfs create -o mountpoint=/var/lib -o canmount=off d/varlib

zpool create -f "${ZPOOL_OPTS[@]}" -O mountpoint=/m m raidz2 "${M_DISKS[@]}"
