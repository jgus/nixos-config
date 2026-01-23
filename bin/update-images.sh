#!/usr/bin/env nix-shell
#! nix-shell -i bash -p nix-prefetch-docker skopeo

set -euo pipefail

: ${NIXOS_CONFIG_ROOT:?"NIXOS_CONFIG_ROOT must be set"}
IMAGES_DIR="${NIXOS_CONFIG_ROOT}/images"

cd "${IMAGES_DIR}"

for nix_file in *.nix; do
    echo "Checking ${nix_file}..."

    # Parse the nix expression to extract finalImageName, finalImageTag, and imageDigest
    finalImageName=$(nix eval --raw -f "${nix_file}" finalImageName 2>/dev/null)
    finalImageTag=$(nix eval --raw -f "${nix_file}" finalImageTag 2>/dev/null)
    imageDigest=$(nix eval --raw -f "${nix_file}" imageDigest 2>/dev/null)

    # Get current digest from skopeo
    currentDigest=$(skopeo inspect docker://"${finalImageName}:${finalImageTag}" --format '{{.Digest}}' 2>/dev/null || echo "")

    # Compare digests
    if [[ "${currentDigest}" != "${imageDigest}" ]]; then
        echo "Updating ${nix_file}: ${finalImageName}:${finalImageTag}"
        echo "  Old digest: ${imageDigest}"
        echo "  New digest: ${currentDigest}"
        (nix-prefetch-docker --quiet --image-name "${finalImageName}" --image-tag "${finalImageTag}" > "${nix_file}") &
    fi
done

echo "Waiting for downloads..."
wait
