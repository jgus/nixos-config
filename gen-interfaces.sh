#!/usr/bin/env -S bash -e

echo "{ ... }: {"
for i in $(ip --brief link | cut -d ' ' -f1 | grep "^eth\|^en")
do
    echo "  networking.interfaces.${i}.useDHCP = true;"
done
echo "}"
