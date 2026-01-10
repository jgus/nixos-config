#!/usr/bin/env bash
#
# Build, test, and switch all machines from this host (cross-compiling as needed).
# This script builds all configurations locally, then deploys to remote machines.
#
# Usage: nixos-deploy-all.sh [--switch]
#   Without --switch: builds and tests all configurations
#   With --switch: also performs the switch phase
#

set -euo pipefail

# Parse arguments
DO_SWITCH=false
for arg in "$@"; do
    case "$arg" in
        --switch)
            DO_SWITCH=true
            ;;
        *)
            echo "Unknown argument: $arg"
            echo "Usage: $0 [--switch]"
            exit 1
            ;;
    esac
done

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "$0")" ; pwd)"
cd "${SCRIPT_DIR}/.."

# Get current hostname
CURRENT_HOST="$(hostname)"

# List of all machines
ALL_MACHINES=(c1-2 d1 pi-67cba1 c1-1 b1)

# Reorder so current machine is first (if it's in the list)
MACHINES=()
for machine in "${ALL_MACHINES[@]}"; do
    if [[ "${machine}" == "${CURRENT_HOST}" ]]; then
        MACHINES=("${machine}" "${MACHINES[@]}")
    else
        MACHINES+=("${machine}")
    fi
done

# Result directory for GC roots (keeps builds from being garbage collected)
RESULT_DIR="/etc/nixos/gcroots"
mkdir -p "${RESULT_DIR}"

echo "========================================"
echo "Building configurations for all machines"
echo "Current machine: ${CURRENT_HOST}"
echo "Machine order: ${MACHINES[*]}"
echo "Switch phase: ${DO_SWITCH}"
echo "========================================"
echo ""

#
# Phase 0: Verify SSH and vkey backups for all machines
#
echo "=== Phase 0: Verifying SSH and vkey backups ==="
echo ""

# Call verification script (try PATH first for packaged case, then fall back to relative path)
if command -v verify-sops-backups &>/dev/null; then
    verify-sops-backups
else
    "${SCRIPT_DIR}/verify-sops-backups.sh"
fi

echo ""

#
# Phase 1: Build all configurations locally
#
echo "=== Phase 1: Building all configurations ==="

nix-channel --update

for machine in "${MACHINES[@]}"; do
    echo ""
    echo "--- Building configuration for ${machine} ---"
    # Build and create a GC root symlink
    MACHINE_ID="${machine}" nix-build '<nixpkgs/nixos>' -A config.system.build.toplevel -o "${RESULT_DIR}/${machine}"
    echo "✓ Build successful for ${machine}"
done

echo ""
echo "=== All builds successful ==="
echo ""

#
# Phase 2: Test all configurations
#
echo "=== Phase 2: Testing all configurations ==="
for machine in "${MACHINES[@]}"; do
    echo ""
    echo "--- Testing configuration for ${machine} ---"
    if [[ "${machine}" == "${CURRENT_HOST}" ]]; then
        # Local machine - no --target-host needed
        MACHINE_ID="${machine}" nixos-rebuild test
    else
        # Remote machine - use --target-host
        MACHINE_ID="${machine}" nixos-rebuild test --target-host "${machine}"
    fi
    echo "✓ Test successful for ${machine}"
done

echo ""
echo "=== All tests successful ==="
echo ""

#
# Phase 3: Switch all configurations (only if --switch was passed)
#
if [[ "${DO_SWITCH}" == "true" ]]; then
    echo "=== Phase 3: Switching all configurations ==="
    for machine in "${MACHINES[@]}"; do
        echo ""
        echo "--- Switching configuration for ${machine} ---"
        if [[ "${machine}" == "${CURRENT_HOST}" ]]; then
            # Local machine - no --target-host needed
            MACHINE_ID="${machine}" nixos-rebuild boot
        else
            # Remote machine - use --target-host
            MACHINE_ID="${machine}" nixos-rebuild boot --target-host "${machine}"
        fi
        echo "✓ Switch successful for ${machine}"
    done

    echo ""
    echo "=== All switches successful ==="
    echo ""
else
    echo "=== Skipping switch phase (use --switch to enable) ==="
    echo ""
fi

echo "========================================"
echo "All machines successfully updated!"
echo "========================================"
echo ""
echo "GC roots preserved in: ${RESULT_DIR}/"
ls -la "${RESULT_DIR}/"
