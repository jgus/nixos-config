#!/usr/bin/env -S bash -e

(
    echo "{ ... }: {"
    for i in $(ip link | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]"{print $2;getline}')
    do
        echo "  networking.interfaces.${i}.useDHCP = true;"
    done
    echo "}"
) >/etc/nixos/interfaces.nix
