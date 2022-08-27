#!/usr/bin/env -S bash -e

(
    echo "{ ... }: {"
    echo "  networking.bridges.br0.interfaces = ["
    for i in $(ip --brief link | cut -d ' ' -f1 | grep "eth\|enp")
    do
        echo "    \"${i}\""
    done
    echo "  ];"
    echo "  networking.interfaces.br0.useDHCP = true;"
    echo "}"
) >/etc/nixos/interfaces.nix
