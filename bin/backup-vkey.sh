#! /usr/bin/env nix-shell
#! nix-shell -i bash -p sops

set -euo pipefail

# Default values
SOURCE_FILE="${SOURCE_FILE:-/boot/.secrets/vkey}"
TARGET_FILE="${TARGET_FILE:-/etc/nixos/secrets/$(hostname)/vkey}"

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
            echo "Back up vkey as a sops-encrypted binary file."
            echo ""
            echo "Options:"
            echo "  --source FILE   Source vkey file (default: /boot/.secrets/vkey)"
            echo "  --target FILE   Target file for encrypted backup (default: /etc/nixos/secrets/\$(hostname)/vkey)"
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
echo "Backing up vkey"
echo "========================================"
echo "Source: ${SOURCE_FILE}"
echo "Target: ${TARGET_FILE}"
echo "========================================"
echo ""

# Copy the vkey to the target location
cp "${SOURCE_FILE}" "${TARGET_FILE}"

# Encrypt the vkey with sops in-place
sops -e -i "${TARGET_FILE}"

echo ""
echo "========================================"
echo "Backup complete!"
echo "Backed up vkey to:"
echo "  ${TARGET_FILE}"
echo "========================================"
echo ""
echo "To restore, run:"
echo "  restore-vkey.sh --source ${TARGET_FILE} --target ${SOURCE_FILE}"
