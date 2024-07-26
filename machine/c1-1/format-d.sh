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
    -O mountpoint=/d
    -O encryption=on
    -O keyformat=raw
    -O keylocation=file:///boot/.secrets/vkey
)

ZPOOL_TYPE=raidz3

zpool create -f "${ZPOOL_OPTS[@]}" d ${ZPOOL_TYPE} $(for i in {0..22} {24..28}; do echo /dev/disk/by-path/pci-0000\:0d\:00.0-scsi-0\:0\:${i}\:0; done)

