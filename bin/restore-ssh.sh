#! /usr/bin/env nix-shell
#! nix-shell -i bash -p sops openssh ssh-to-age

set -euo pipefail

# Default values
SOURCE_DIR="${SOURCE_DIR:-/etc/nixos/secrets/$(hostname)/ssh}"
TARGET_DIR="${TARGET_DIR:-/etc/ssh}"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --source)
            SOURCE_DIR="$2"
            shift 2
            ;;
        --target)
            TARGET_DIR="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--source SOURCE_DIR] [--target TARGET_DIR]"
            echo ""
            echo "Restore SSH host keys from sops-encrypted binary files."
            echo "Extracts public keys from private keys automatically."
            echo ""
            echo "Options:"
            echo "  --source DIR    Source directory containing encrypted backups (default: /etc/nixos/secrets/\$(hostname)/ssh)"
            echo "  --target DIR    Target directory for restored keys (default: /etc/ssh)"
            echo "  -h, --help      Show this help message"
            echo ""
            echo "Environment variables:"
            echo "  SOURCE_DIR      Same as --source"
            echo "  TARGET_DIR      Same as --target"
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate source directory
if [[ ! -d "${SOURCE_DIR}" ]]; then
    echo "Error: Source directory does not exist: ${SOURCE_DIR}"
    exit 1
fi

# Create target directory
mkdir -p "${TARGET_DIR}"

echo "========================================"
echo "Restoring SSH host keys"
echo "========================================"
echo "Source: ${SOURCE_DIR}"
echo "Target: ${TARGET_DIR}"
echo "========================================"
echo ""

# Find and restore all encrypted private keys
RESTORE_COUNT=0
for key_file in "${SOURCE_DIR}"/ssh_host_*_key; do
    # Skip if no files match the pattern
    [[ -f "${key_file}" ]] || continue

    # Skip public keys (those ending in .pub)
    [[ "${key_file}" == *.pub ]] && continue

    # Get the base filename
    key_name=$(basename "${key_file}")
    private_key_path="${TARGET_DIR}/${key_name}"
    public_key_path="${TARGET_DIR}/${key_name}.pub"

    echo "Restoring: ${key_name}"

    # Decrypt the private key with sops
    sops -d "${key_file}" > "${private_key_path}"

    # Set correct permissions on private key
    chmod 0400 "${private_key_path}"

    # Extract public key from private key
    ssh-keygen -y -f "${private_key_path}" > "${public_key_path}"

    # Set correct permissions on public key
    chmod 0444 "${public_key_path}"

    RESTORE_COUNT=$((RESTORE_COUNT + 1))
done

ssh-to-age -private-key -i "${TARGET_DIR}/ssh_host_ed25519_key" > "${TARGET_DIR}/age-host-key.txt"
chmod 0400 "${TARGET_DIR}/age-host-key.txt"

echo ""
echo "========================================"
echo "Restore complete!"
echo "Restored ${RESTORE_COUNT} key pair(s) to:"
echo "  ${TARGET_DIR}"
echo "========================================"
echo ""
