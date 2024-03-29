#!/usr/bin/env -S bash -e

SCRIPT_DIR="$(cd "$(dirname "$0")" ; pwd)"

BRANCH="${BRANCH:-main}"

mountpoint -q /mnt || ( echo "!!! Root not mounted at /mnt"; exit 1 )
mountpoint -q /mnt/boot || ( echo "!!! Boot not mounted at /mnt/boot"; exit 1 )

echo "### Git initialization"
nix-shell -p git --run "
git config --global init.defaultBranch main
git config --global user.email root@localhost
git config --global user.name root
cp /root/.gitconfig /mnt/root/.gitconfig
git clone -b ${BRANCH} https://github.com/jgus/nixos-config.git /mnt/etc/nixos
"

echo "### Generating hardware configuration"
nixos-generate-config --root /mnt
sed -i 's/fsType = "zfs"/fsType = "zfs"; options = [ "zfsutil" ]/' /mnt/etc/nixos/hardware-configuration.nix

/mnt/etc/nixos/gen-interfaces.sh >/mnt/etc/nixos/interfaces.nix

sed -i "s/HOSTID/$(head -c4 /dev/urandom | od -A none -t x4 | xargs)/g" /mnt/etc/nixos/host.nix

echo "### Installing"
nixos-install

echo "### Done! Ready to reboot"
