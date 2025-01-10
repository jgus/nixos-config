#!/usr/bin/env -S bash -e

ARGS="$@"

SCRIPT_DIR="$(cd "$(dirname "$0")" ; pwd)"

source "${SCRIPT_DIR}/functions.sh"

echo "#"
echo "# Updating & Testing"
echo "#"

on_all_servers "cd /etc/nixos; git pull && nixos-rebuild --upgrade build"

echo "#"
echo "# Build successful"
echo "#"

if [[ "x${ARGS}" != "x" ]]
then
    echo "#"
    echo "# Running nixos-rebuild ${ARGS}"
    echo "#"

    on_all_servers "nixos-rebuild ${ARGS}"

    echo "#"
    echo "# ${ARGS} successful"
    echo "#"
fi
