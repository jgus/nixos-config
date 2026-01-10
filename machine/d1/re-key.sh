#! /usr/bin/env nix-shell
#! nix-shell -i bash --packages bash coreutils zfs

set -e

dd if=/dev/random of=/boot/vkey bs=32 count=1

for z in d f
do
  zfs	change-key -o "keylocation=file:///boot/vkey" ${z}
done
