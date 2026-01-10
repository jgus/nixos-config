#! /usr/bin/env nix-shell
#! nix-shell -i bash -p sops

set -euo pipefail

# Default values
SOURCE_DIR="${SOURCE_DIR:-/etc/ssh}"
TARGET_DIR="${TARGET_DIR:-/etc/nixos/secrets/$(hostname)/ssh}"

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
            echo "Back up SSH host private keys as sops-encrypted binary files."
            echo ""
            echo "Options:"
            echo "  --source DIR    Source directory containing SSH keys (default: /etc/ssh)"
            echo "  --target DIR    Target directory for encrypted backups (default: /etc/nixos/secrets/\$(hostname)/ssh)"
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
echo "Backing up SSH host keys"
echo "========================================"
echo "Source: ${SOURCE_DIR}"
echo "Target: ${TARGET_DIR}"
echo "========================================"
echo ""

# Find and backup all private keys
BACKUP_COUNT=0
for key_file in "${SOURCE_DIR}"/ssh_host_*_key; do
    # Skip if no files match the pattern
    [[ -f "${key_file}" ]] || continue

    # Skip public keys (those ending in .pub)
    [[ "${key_file}" == *.pub ]] && continue

    # Get the base filename
    key_name=$(basename "${key_file}")

    echo "Backing up: ${key_name}"

    # Copy the key to the target location
    cp "${key_file}" "${TARGET_DIR}/${key_name}"

    # Encrypt the private key with sops in-place
    sops -e -i "${TARGET_DIR}/${key_name}"

    BACKUP_COUNT=$((BACKUP_COUNT + 1))
done

echo ""
echo "========================================"
echo "Backup complete!"
echo "Backed up ${BACKUP_COUNT} private key(s) to:"
echo "  ${TARGET_DIR}"
echo "========================================"
echo ""
echo "To restore, run:"
echo "  restore-ssh.sh --source ${TARGET_DIR} --target ${SOURCE_DIR}"