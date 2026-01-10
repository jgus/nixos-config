#! /usr/bin/env nix-shell
#! nix-shell -i bash -p sops

set -euo pipefail

# Default values
SOURCE_FILE="${SOURCE_FILE:-/etc/nixos/secrets/$(hostname)/vkey}"
TARGET_FILE="${TARGET_FILE:-/boot/.secrets/vkey}"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --source)
            SOURCE_FILE="$2"
            shift 2
            ;;
        --target)
            TARGET_FILE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--source SOURCE_FILE] [--target TARGET_FILE]"
            echo ""
            echo "Restore vkey from a sops-encrypted binary file."
            echo ""
            echo "Options:"
            echo "  --source FILE   Source encrypted vkey file (default: /etc/nixos/secrets/\$(hostname)/vkey)"
            echo "  --target FILE   Target file for restored vkey (default: /boot/.secrets/vkey)"
            echo "  -h, --help      Show this help message"
            echo ""
            echo "Environment variables:"
            echo "  SOURCE_FILE     Same as --source"
            echo "  TARGET_FILE     Same as --target"
            exit 0
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate source file
if [[ ! -f "${SOURCE_FILE}" ]]; then
    echo "Error: Source file does not exist: ${SOURCE_FILE}"
    exit 1
fi

# Create target directory
mkdir -p "$(dirname "${TARGET_FILE}")"

echo "========================================"
echo "Restoring vkey"
echo "========================================"
echo "Source: ${SOURCE_FILE}"
echo "Target: ${TARGET_FILE}"
echo "========================================"
echo ""

# Decrypt the vkey with sops
sops -d "${SOURCE_FILE}" > "${TARGET_FILE}"

# Set correct permissions on vkey
chmod 0400 "${TARGET_FILE}"

echo ""
echo "========================================"
echo "Restore complete!"
echo "Restored vkey to:"
echo "  ${TARGET_FILE}"
echo "========================================"
echo ""