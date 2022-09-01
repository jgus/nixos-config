#!/usr/bin/env -S bash -e

SWAP_SIZE_="${SWAP_SIZE:-0%}"

Z_DEVS=()

[ -f /boot/vkey ] || dd bs=1 count=32 if=/dev/urandom of=/boot/vkey

if [[ "${SWAP_SIZE}" == "0%" ]]
then
    Z_DEVS=("$@")
else
    for d in "$@"
    do
        parted ${d} -- mklabel gpt
        parted ${d} -- mkpart primary linux-swap 0% ${SWAP_SIZE}
        parted ${d} -- mkpart primary ${SWAP_SIZE} 100%
        sleep 2
        Z_DEVS+=("${d}-part2")
        mkswap "${d}-part1"
        swapon -p 0 "${d}-part1"
    done

    nixos-generate-config
fi

ZPOOL_OPTS=(
    -o ashift=12
    -O acltype=posixacl
    -O aclinherit=passthrough
    -O compression=lz4
    -O dnodesize=auto
    -O normalization=formD
    -O relatime=on
    -O xattr=sa
    -O com.sun:auto-snapshot=true
    -O encryption=aes-256-gcm
    -O keyformat=raw
    -O keylocation=file:///boot/vkey
)

zpool create -f "${ZPOOL_OPTS[@]}" d raidz3 "${Z_DEVS[@]}"
