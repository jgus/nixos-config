#!/usr/bin/env -S bash -e

echo "### Formatting root as zfs"
ZPOOL_OPTS=(
    -o ashift=12
    -O acltype=posixacl
    -O aclinherit=passthrough
    -O compression=lz4
    -O dnodesize=auto
    -O normalization=formD
    -O relatime=on
    -O xattr=sa
    -O mountpoint=/
    -O recordsize=16k
    -R /mnt
)

DEVS=()
for d in /dev/disk/by-partlabel/root*
do
    DEVS+=(/dev/disk/by-partuuid/$(blkid -o value -s PARTUUID "${d}"))
done

ZPOOL_TYPE=${ZPOOL_TYPE:-mirror}
if (( ${#DEVS[@]} <= 1 ))
then
    ZPOOL_TYPE=""
fi
zpool create -f "${ZPOOL_OPTS[@]}" r ${ZPOOL_TYPE} "${DEVS[@]}"

zfs create -o mountpoint=/etc/nixos r/nixos
zfs create                          r/home
zfs create -o mountpoint=/root      r/home/root
zfs create -o mountpoint=/var/lib   r/varlib

echo "### Formatting boot"
mkfs.fat -F 32 -n boot0 /dev/disk/by-partlabel/boot0
mkdir -p /mnt/boot
mount /dev/disk/by-partlabel/boot0 /mnt/boot

i=1
while [ -b /dev/disk/by-partlabel/boot${i} ]
do
    mkfs.fat -F 32 -n boot${i} /dev/disk/by-partlabel/boot${i}
    mkdir -p /mnt/boot/${i}
    mount /dev/disk/by-partlabel/boot${i} /mnt/boot/${i}
    ((i+=1))
done

echo "### Formatting swap"
for d in $(ls /dev/disk/by-partlabel/swap*)
do
    mkswap "${d}"
    swapon "${d}"
done
free -h
