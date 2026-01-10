#!/usr/bin/env -S bash -e

HDD_ZPOOL_OPTS=(
    -o ashift=12
    -O compression=lz4
    -O acltype=posixacl
    -O aclinherit=passthrough
    -O dnodesize=auto
    -O normalization=formD
    -O relatime=on
    -O xattr=sa
    -O encryption=on
    -O keyformat=raw
    -O keylocation=file:///boot/vkey
    -O autobackup:snap-$(hostname)=true
)

SSD_ZPOOL_OPTS=(
    -o ashift=12
    -O compression=lz4
    -O acltype=posixacl
    -O aclinherit=passthrough
    -O dnodesize=auto
    -O normalization=formD
    -O relatime=on
    -O xattr=sa
    -O autobackup:snap-$(hostname)=true
)

S_DISKS=(
    /dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:0:0
    /dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:1:0
    /dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:2:0
    /dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:3:0
    /dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:4:0
)


D_DISKS=(
    /dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:5:0
    /dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:6:0
    /dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:7:0
    /dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:8:0
    /dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:9:0
    /dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:10:0
    /dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:11:0
    /dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:12:0
    /dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:13:0
    /dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:14:0
    /dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:15:0
    /dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:16:0
    /dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:17:0
    /dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:18:0
)

F_DISKS=(
    /dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:19:0
    /dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:20:0
    /dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:21:0
    /dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:22:0
    /dev/disk/by-path/pci-0000:03:00.0-scsi-0:0:23:0
)


mdadm --create /dev/md/s --level=0 --raid-devices=${#S_DISKS[@]} "${S_DISKS[@]}" --chunk=1024 --uuid=a2edf378:c1efcb74:731a6323:d961e11d
mkfs.xfs -d su=1024k,sw=${#S_DISKS[@]} /dev/md/s

zpool create "${SSD_ZPOOL_OPTS[@]}" -O recordsize=1M -O mountpoint=/s s "${S_DISKS[@]}"

zpool create "${HDD_ZPOOL_OPTS[@]}" -O recordsize=128K -O mountpoint=/d d raidz3 "${D_DISKS[@]}"

zpool create "${HDD_ZPOOL_OPTS[@]}" -O recordsize=16K -O mountpoint=/f f raidz "${F_DISKS[@]}"
