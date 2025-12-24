{ pkgs, ... }:
let
  secretArchive = pkgs.runCommandLocal "secretArchive" { } ''
    mkdir ''${out}
    KEY=$(${pkgs.openssl}/bin/openssl rand 32 | base64 -w0)
    KEY_ENC=$(echo ''${KEY} | base64 -d | ${pkgs.openssl}/bin/openssl pkeyutl -encrypt -pubin -inkey <(${pkgs.openssh}/bin/ssh-keygen -e -f ${./pubkeys/josh-rsa} -m PKCS8) | base64 -w0)
    ARK_ENC=$(cd ${./.secrets}; tar c * | ${pkgs.openssl}/bin/openssl aes-256-cbc -pbkdf2 -pass file:<(echo ''${KEY} | base64 -d) | base64 -w0)
    cat << EOF > ''${out}/archive.sh
    #! /usr/bin/env nix-shell
    #! nix-shell -i bash -p openssl
    if [ "\$1x" == "x" ]
    then
      echo "Usage: \$0 <private/key/file>" >&2
      exit 1
    fi
    echo "''${ARK_ENC}" | base64 -d | openssl aes-256-cbc -d -pbkdf2 -pass file:<(echo "''${KEY_ENC}" | base64 -d | openssl pkeyutl -decrypt -inkey "\$1") | tar x
    EOF
    chmod a+x ''${out}/archive.sh
  '';
in
{
  systemd.services = {
    backup-secrets = {
      path = with pkgs; [
        hostname
        rsync
      ];
      script = ''
        rsync -arP ${secretArchive}/archive.sh /storage/backup/nixos/''$(hostname)-secrets.sh
      '';
      serviceConfig = {
        Type = "oneshot";
      };
      wantedBy = [ "multi-user.target" ];
      requires = [ "nfs-mountd.service" "storage-backup.mount" ];
    };
  };
}
