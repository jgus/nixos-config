#!/usr/bin/env -S bash -e

SCRIPT_DIR="$(cd "$(dirname "$0")" ; pwd)"

BRANCH="${BRANCH:-main}"

[[ "x${MACHINE_ID}" != "x" ]] || ( echo "!!! MACHINE_ID not specified"; exit 1 )

echo "### Git initialization"
rm -rf /etc/nixos
nix-shell -p git --run "
git config --global init.defaultBranch main
git config --global user.email root@localhost
git config --global user.name root
git clone -b ${BRANCH} https://github.com/jgus/nixos-config.git /etc/nixos
"

echo -n "${MACHINE_ID}" >/mnt/etc/nixos/machine-id.nix

mkdir -p /etc/nixos/.secrets
[ -f /mnt/etc/nixos/.secrets/passwords.nix ] || echo "{}" >/mnt/etc/nixos/.secrets/passwords.nix
mkdir -p /mnt/etc/nixos/.secrets/etc/ssh
ssh-keygen -A -f /mnt/etc/nixos/.secrets

echo "### Installing"
nix-channel --add https://github.com/NixOS/nixos-hardware/archive/master.tar.gz nixos-hardware
nix-channel --update
nixos-rebuild boot

echo "### Done! Ready to reboot"
