let
  pubkeys = import ./pubkeys.nix;
in
{ config, pkgs, lib, ... }:
let
  archive = pkgs.runCommand "secrets-backup" { } ''
    KEY=$(${pkgs.openssl}/bin/openssl rand 32 | base64 -w0)
    KEY_ENC=$(echo ''${KEY} | base64 -d | ${pkgs.openssl}/bin/openssl pkeyutl -encrypt -pubin -inkey <(${pkgs.openssh}/bin/ssh-keygen -e -f ${pkgs.writeText "id_rsa.pub" pubkeys.josh-rsa} -m PKCS8) | base64 -w0)
    ARK_ENC=$(cd ${./.secrets}; ${pkgs.gnutar}/bin/tar c ./* | ${pkgs.openssl}/bin/openssl aes-256-cbc -pbkdf2 -pass file:<(echo ''${KEY} | base64 -d) | base64 -w0)
    mkdir ''${out}
    cat << EOF > ''${out}/archive.sh
    #! /usr/bin/env nix-shell
    #! nix-shell -i bash -p openssl
    PKEY=\$1
    if ! [ -f "\''${PKEY}" ]
    then
      echo "Usage: \$0 <private/key/file>"
      exit 1
    fi
    echo "''${ARK_ENC}" | base64 -d | openssl aes-256-cbc -d -pbkdf2 -pass file:<(echo "''${KEY_ENC}" | base64 -d | openssl pkeyutl -decrypt -inkey "\''${PKEY}") | tar xv
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
        rsync -arP ${archive}/archive.sh /storage/backup/nixos/''$(hostname)-secrets.sh
      '';
      serviceConfig = {
        Type = "oneshot";
      };
      wantedBy = [ "multi-user.target" ];
      requires = [ "nfs-mountd.service" ];
    };
  };
}
