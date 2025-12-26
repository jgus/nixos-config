{ pkgs, ... }:
let
  user = "user";
  group = "users";

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

  # All file setup with permissions (chmod works here, only chown needs fakeroot)
  etcFiles = pkgs.runCommand "landing-etc" { } ''
    mkdir -p $out/etc/ssh
    mkdir -p $out/home/${user}/.ssh
    mkdir -p $out/var/empty

    # User files
    echo "${user}:x:1000:1000:${group}:/home/${user}:/bin/bash" > $out/etc/passwd
    echo "sshd:x:74:74:Privilege-separated SSH:/var/empty/sshd:/sbin/nologin" >> $out/etc/passwd
    echo "${group}:x:1000:" > $out/etc/group
    echo "sshd:x:74:" >> $out/etc/group
    echo "${user}:*:1::::::" > $out/etc/shadow

    # SSH config
    cp ${sshd_config} $out/etc/ssh/sshd_config

    # SSH host keys
    cp ${./../.secrets/landing/etc/ssh}/ssh_host_* $out/etc/ssh/

    # User's authorized_keys
    cp ${./../pubkeys/backup-rsa} $out/home/${user}/.ssh/authorized_keys
  '';

  landingImage = pkgs.dockerTools.buildLayeredImage {
    name = "landing";
    tag = "latest";

    contents = [
      pkgs.openssh
      pkgs.tini
      pkgs.bashInteractive
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
  docker = {
    image = "landing:latest";
    imageFile = landingImage;
  };
}
