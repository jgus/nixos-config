{ pkgs, ... }:
let
  user = "user";
  group = "users";

  files = {
    etc_passwd = pkgs.writeText "etc_passwd" ''
      ${user}:x:1000:1000:${group}:/home/${user}:/bin/bash
      sshd:x:74:74:Privilege-separated SSH:/var/empty/sshd:/sbin/nologin
    '';

    etc_group = pkgs.writeText "etc_group" ''
      ${group}:x:1000:
      sshd:x:74:
    '';

    etc_shadow = pkgs.writeText "etc_shadow" ''
      ${user}:*:1::::::
    '';

    # SSH configuration
    sshd_config = pkgs.writeText "sshd_config" ''
      PermitRootLogin no
      AuthorizedKeysFile .ssh/authorized_keys
      PasswordAuthentication no
      AllowTcpForwarding yes
      Subsystem sftp internal-sftp
      HostKey /etc/ssh/ssh_host_rsa_key
      HostKey /etc/ssh/ssh_host_ecdsa_key
      HostKey /etc/ssh/ssh_host_ed25519_key
    '';
  };

  # All file setup with permissions (chmod works here, only chown needs fakeroot)
  etcFiles = pkgs.runCommand "landing-etc" { } ''
    mkdir -p $out/var/empty

    # User files
    mkdir -p $out/etc
    cp ${files.etc_passwd} $out/etc/passwd
    cp ${files.etc_group} $out/etc/group
    cp ${files.etc_shadow} $out/etc/shadow

    # SSH config
    mkdir -p $out/etc/ssh
    cp ${files.sshd_config} $out/etc/ssh/sshd_config
    cp ${./../.secrets/ssh/landing}/ssh_host_* $out/etc/ssh/
    cp ${./../pubkeys/landing}/ssh_host_* $out/etc/ssh/

    # User's authorized_keys
    mkdir -p $out/home/${user}/.ssh
    cp ${./../pubkeys/backup-rsa} $out/home/${user}/.ssh/authorized_keys
  '';

  landingImage = pkgs.dockerTools.buildLayeredImage {
    name = "landing";
    tag = "latest";

    contents = with pkgs; [
      bashInteractive
      openssh
      tini
    ];

    # fakeRootCommands: copy our etc files and set ownership
    fakeRootCommands = ''
      rm -rf ./etc/ssh
      cp -rL ${etcFiles}/* ./
      chmod 640 ./etc/shadow
      chmod 644 ./etc/ssh/*
      chmod 600 ./etc/ssh/ssh_host_*_key
      chmod 700 ./home/${user}/.ssh
      chmod 600 ./home/${user}/.ssh/authorized_keys
      chown -R 1000:1000 ./home/${user}
    '';

    config = {
      Entrypoint = [ "${pkgs.tini}/bin/tini" "--" ];
      Cmd = [ "${pkgs.openssh}/bin/sshd" "-D" "-e" ];
      ExposedPorts."22/tcp" = { };
    };
  };
in
{
  configStorage = false;
  container = {
    image = "landing:latest";
    imageFile = landingImage;
  };
}
