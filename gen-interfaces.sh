#!/usr/bin/env -S bash -e

(
    echo "{ ... }: {"
    echo "  networking.bridges.br0.interfaces = ["
    for i in $(ip link | awk -F: '$0 ~ "enp"{print $2;getline}')
    do
        echo "    \"${i}\""
    done
    echo "  ];"
    echo "  networking.interfaces.br0.useDHCP = true;"
    echo "}"
) >/etc/nixos/interfaces.nix
