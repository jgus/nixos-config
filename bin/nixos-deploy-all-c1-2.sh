#!/usr/bin/env bash

set -euo pipefail

SSH_HOST="josh@c1-2"
REMOTE_DIR="/service/code-server/git/nixos-config"

ssh -t "${SSH_HOST}" "cd ${REMOTE_DIR} && direnv exec . sudo --preserve-env=NIXOS_CONFIG_ROOT --preserve-env=SSH_AUTH_SOCK nixos-deploy-all $*"
