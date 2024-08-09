#!/usr/bin/env -S bash -e

ARGS="$@"

SCRIPT_DIR="$(cd "$(dirname "$0")" ; pwd)"

source "${SCRIPT_DIR}/functions.sh"

on_all_servers "${ARGS}"
