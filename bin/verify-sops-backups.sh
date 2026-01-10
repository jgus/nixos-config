#!/usr/bin/env nix-shell
#! nix-shell -i bash -p sops

set -euo pipefail

# Helper function to check if a value is in a list
in_list() {
    local needle="$1"
    shift
    local haystack=("$@")
    for item in "${haystack[@]}"; do
        if [[ "${needle}" == "${item}" ]]; then
            return 0
        fi
    done
    return 1
}

# Get current hostname
CURRENT_HOST="$(hostname)"

# List of all machines
MACHINES=(c1-2 d1 pi-67cba1 c1-1 b1)

echo "========================================"
echo "Verifying SSH and vkey backups"
echo "Current machine: ${CURRENT_HOST}"
echo "========================================"

RET=0

for machine in "${MACHINES[@]}"; do
    # Determine if this is a local or remote machine
    if [[ "${machine}" == "${CURRENT_HOST}" ]]; then
        SSH_CMD=""
    else
        SSH_CMD="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 ${machine}"
    fi
    
    # 1. Verify public host keys match /etc/nixos/pubkeys
    PUBKEY_DIR="/etc/nixos/pubkeys/${machine}"
    if [[ ! -d "${PUBKEY_DIR}" ]]; then
        echo "  ✗ Public key directory missing: ${PUBKEY_DIR}"
        RET=1
    else
        # Get expected public keys from ./pubkeys
        EXPECTED_PUBKEYS=()
        for pubkey_file in "${PUBKEY_DIR}"/ssh_host_*.pub; do
            [[ -f "${pubkey_file}" ]] || continue
            EXPECTED_PUBKEYS+=("$(basename "${pubkey_file}")")
        done
        
        # Get actual public keys from the machine
        ACTUAL_PUBKEYS=()
        if ${SSH_CMD} test -d /etc/ssh 2>/dev/null; then
            while IFS= read -r -d '' pubkey_file; do
                ACTUAL_PUBKEYS+=("$(basename "${pubkey_file}")")
            done < <(${SSH_CMD} find /etc/ssh -maxdepth 1 -name 'ssh_host_*.pub' -print0 2>/dev/null)
        fi
        
        # Check for missing keys (in pubkeys but not on machine)
        for expected_key in "${EXPECTED_PUBKEYS[@]}"; do
            if ! in_list "${expected_key}" "${ACTUAL_PUBKEYS[@]}"; then
                echo "  ✗ Missing public key on ${machine}: ${expected_key}"
                RET=1
            fi
        done
        
        # Check for extra keys (on machine but not in pubkeys)
        for actual_key in "${ACTUAL_PUBKEYS[@]}"; do
            if ! in_list "${actual_key}" "${EXPECTED_PUBKEYS[@]}"; then
                echo "  ✗ Extra public key on ${machine}: ${actual_key}"
                RET=1
            fi
        done
        
        # Check that values match
        for expected_key in "${EXPECTED_PUBKEYS[@]}"; do
            if in_list "${expected_key}" "${ACTUAL_PUBKEYS[@]}"; then
                EXPECTED_CONTENT=$(cat "${PUBKEY_DIR}/${expected_key}")
                ACTUAL_CONTENT=$(${SSH_CMD} cat "/etc/ssh/${expected_key}" 2>/dev/null || echo "")
                if [[ "${EXPECTED_CONTENT}" != "${ACTUAL_CONTENT}" ]]; then
                    echo "  ✗ Public key content mismatch on ${machine}: ${expected_key}"
                    RET=1
                fi
            fi
        done
    fi
    
    # 2. Verify private SSH keys match secret backups
    SECRET_SSH_DIR="/etc/nixos/secrets/${machine}/ssh"
    if [[ ! -d "${SECRET_SSH_DIR}" ]]; then
        echo "  ✗ Secret SSH directory missing: ${SECRET_SSH_DIR}"
        RET=1
    else
        # Get expected private keys from secrets
        EXPECTED_PRIVKEYS=()
        for privkey_file in "${SECRET_SSH_DIR}"/ssh_host_*_key; do
            [[ -f "${privkey_file}" ]] || continue
            EXPECTED_PRIVKEYS+=("$(basename "${privkey_file}")")
        done
        
        # Get actual private keys from the machine
        ACTUAL_PRIVKEYS=()
        if ${SSH_CMD} test -d /etc/ssh 2>/dev/null; then
            while IFS= read -r -d '' privkey_file; do
                ACTUAL_PRIVKEYS+=("$(basename "${privkey_file}")")
            done < <(${SSH_CMD} find /etc/ssh -maxdepth 1 -name 'ssh_host_*_key' ! -name '*.pub' -print0 2>/dev/null)
        fi
        
        # Check for missing keys (in secrets but not on machine)
        for expected_key in "${EXPECTED_PRIVKEYS[@]}"; do
            if ! in_list "${expected_key}" "${ACTUAL_PRIVKEYS[@]}"; then
                echo "  ✗ Missing private key on ${machine}: ${expected_key}"
                RET=1
            fi
        done
        
        # Check for extra keys (on machine but not in secrets)
        for actual_key in "${ACTUAL_PRIVKEYS[@]}"; do
            if ! in_list "${actual_key}" "${EXPECTED_PRIVKEYS[@]}"; then
                echo "  ✗ Extra private key on ${machine}: ${actual_key}"
                RET=1
            fi
        done
        
        # Check that values match (decrypt secret and compare)
        for expected_key in "${EXPECTED_PRIVKEYS[@]}"; do
            if in_list "${expected_key}" "${ACTUAL_PRIVKEYS[@]}"; then
                # Decrypt the secret key
                DECRYPTED_KEY=$(sops -d "${SECRET_SSH_DIR}/${expected_key}" 2>/dev/null || echo "")
                ACTUAL_KEY=$(${SSH_CMD} cat "/etc/ssh/${expected_key}" 2>/dev/null || echo "")
                if [[ "${DECRYPTED_KEY}" != "${ACTUAL_KEY}" ]]; then
                    echo "  ✗ Private key content mismatch on ${machine}: ${expected_key}"
                    RET=1
                fi
            fi
        done
    fi
    
    # 3. Verify vkey matches (backup exists iff vkey exists on host)
    SECRET_VKEY_FILE="/etc/nixos/secrets/${machine}/vkey"
    
    if [[ -f "${SECRET_VKEY_FILE}" ]]; then
        # Local backup exists - verify remote key exists and matches
        if ${SSH_CMD} test -f /boot/.secrets/vkey 2>/dev/null; then
            DECRYPTED_VKEY=$(sops -d "${SECRET_VKEY_FILE}" 2>/dev/null || echo "")
            ACTUAL_VKEY=$(${SSH_CMD} cat /boot/.secrets/vkey 2>/dev/null || echo "")
            if [[ "${DECRYPTED_VKEY}" != "${ACTUAL_VKEY}" ]]; then
                echo "  ✗ vkey content mismatch on ${machine}"
                RET=1
            fi
        else
            echo "  ✗ vkey backup exists but vkey not on ${machine}"
            RET=1
        fi
    else
        # Local backup does not exist - verify remote key also does not exist
        if ${SSH_CMD} test -f /boot/.secrets/vkey 2>/dev/null; then
            echo "  ✗ vkey exists on ${machine} but backup missing"
            RET=1
        fi
    fi
done

exit ${RET}
