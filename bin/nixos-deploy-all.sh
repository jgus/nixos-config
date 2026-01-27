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

: ${NIXOS_CONFIG_ROOT:?"NIXOS_CONFIG_ROOT must be set"}

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

echo "========================================"
echo "Building configurations for all machines"
echo "NixOS Configuration: ${NIXOS_CONFIG_ROOT}"
echo "Current machine: ${CURRENT_HOST}"
echo "Machine order: ${MACHINES[*]}"
echo "Switch phase: ${DO_SWITCH}"
echo "========================================"
echo ""

echo "=== Verifying SSH and vkey backups ==="
echo ""

# Call verification script (try PATH first for packaged case, then fall back to relative path)
if command -v verify-sops-backups &>/dev/null; then
    verify-sops-backups
else
    "${SCRIPT_DIR}/verify-sops-backups.sh"
fi

echo ""

echo "=== Building all configurations ==="

for machine in "${MACHINES[@]}"; do
    echo ""
    echo "--- Building configuration for ${machine} ---"
    nixos-rebuild build --flake ${NIXOS_CONFIG_ROOT}#${machine} --target-host "${machine}"
    echo "✓ Build successful for ${machine}"
done

echo ""
echo "=== All builds successful ==="
echo ""

echo "=== Testing all configurations ==="
for machine in "${MACHINES[@]}"; do
    echo ""
    echo "--- Testing configuration for ${machine} ---"
    nixos-rebuild test --flake ${NIXOS_CONFIG_ROOT}#${machine} --target-host "${machine}"
    echo "✓ Test successful for ${machine}"
done

echo ""
echo "=== All tests successful ==="
echo ""

if [[ "${DO_SWITCH}" == "true" ]]; then
    echo "=== Switching all configurations ==="
    for machine in "${MACHINES[@]}"; do
        echo ""
        echo "--- Switching configuration for ${machine} ---"
        nixos-rebuild boot --flake ${NIXOS_CONFIG_ROOT}#${machine} --target-host "${machine}"
        echo "✓ Switch successful for ${machine}"
    done

    echo ""
    echo "=== All switches successful ==="
    echo ""

    echo "=== Saving GC roots ==="

    RESULT_DIR="${NIXOS_CONFIG_ROOT}/gcroots"
    rm -rf "${RESULT_DIR}"
    mkdir -p "${RESULT_DIR}"
    for machine in "${MACHINES[@]}"; do
        mkdir "${RESULT_DIR}/${machine}"
    done

    for machine in "${MACHINES[@]}"; do
        echo ""
        echo "--- Building configuration for ${machine} ---"
        cd "${RESULT_DIR}/${machine}"
        nixos-rebuild build --flake ${NIXOS_CONFIG_ROOT}#${machine}
        echo "✓ GC root saved for ${machine}"
    done

    echo ""
    echo "=== All GC roots saved ==="
    echo ""
else
    echo "=== Skipping switch phase (use --switch to enable) ==="
    echo ""
fi

echo "========================================"
echo "All machines successfully updated!"
echo "========================================"
echo ""
