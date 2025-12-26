{ pkgs, ... }:
let
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

  # Authorized keys for the user
  authorizedKeys = builtins.readFile ./../pubkeys/backup-rsa;

  # SSH host keys from secrets directory
  sshHostKeys = ./../.secrets/landing/etc/ssh;

  # Create etc directory structure with proper permissions
  etcFiles = pkgs.runCommand "landing-etc" { } ''
    mkdir -p $out/etc/ssh
    mkdir -p $out/home/user/.ssh
    mkdir -p $out/var/empty
    mkdir -p $out/tmp

    # Create passwd and group files
    echo "root:x:0:0:root:/root:/bin/bash" > $out/etc/passwd
    echo "user:x:1000:1000:user:/home/user:/bin/bash" >> $out/etc/passwd
    echo "sshd:x:74:74:Privilege-separated SSH:/var/empty/sshd:/sbin/nologin" >> $out/etc/passwd
    echo "root:x:0:" > $out/etc/group
    echo "user:x:1000:" >> $out/etc/group
    echo "sshd:x:74:" >> $out/etc/group

    # Create shadow file (empty password field = no password, account not locked)
    # Using * instead of ! because ! means "account locked"
    echo "root:*:1::::::" > $out/etc/shadow
    echo "user:*:1::::::" >> $out/etc/shadow

    # Copy sshd_config
    cp ${sshd_config} $out/etc/ssh/sshd_config

    # Copy SSH host keys
    cp ${sshHostKeys}/ssh_host_rsa_key $out/etc/ssh/
    cp ${sshHostKeys}/ssh_host_rsa_key.pub $out/etc/ssh/
    cp ${sshHostKeys}/ssh_host_ecdsa_key $out/etc/ssh/
    cp ${sshHostKeys}/ssh_host_ecdsa_key.pub $out/etc/ssh/
    cp ${sshHostKeys}/ssh_host_ed25519_key $out/etc/ssh/
    cp ${sshHostKeys}/ssh_host_ed25519_key.pub $out/etc/ssh/

    # Set up authorized_keys for user
    echo "${authorizedKeys}" > $out/home/user/.ssh/authorized_keys
  '';

  # Build the container image at nix build time
  landingImage = pkgs.dockerTools.buildLayeredImage {
    name = "landing";
    tag = "latest";

    contents = [
      pkgs.openssh
      pkgs.coreutils
      pkgs.bash
      pkgs.tini
    ];

    # fakeRootCommands runs as fakeroot, allowing us to set ownership/permissions
    fakeRootCommands = ''
      # Remove openssh's default /etc/ssh (it's a symlink to read-only nix store)
      rm -rf ./etc/ssh

      # Copy our etc structure over
      cp -rL ${etcFiles}/* ./

      # Set correct permissions
      chmod 1777 ./tmp
      chmod 640 ./etc/shadow
      chmod 644 ./etc/ssh/sshd_config

      # Set permissions on host keys (private keys must be 600)
      chmod 600 ./etc/ssh/ssh_host_rsa_key
      chmod 600 ./etc/ssh/ssh_host_ecdsa_key
      chmod 600 ./etc/ssh/ssh_host_ed25519_key
      chmod 644 ./etc/ssh/ssh_host_rsa_key.pub
      chmod 644 ./etc/ssh/ssh_host_ecdsa_key.pub
      chmod 644 ./etc/ssh/ssh_host_ed25519_key.pub

      # Set home directory permissions
      chmod 700 ./home/user/.ssh
      chmod 600 ./home/user/.ssh/authorized_keys
      chown -R 1000:1000 ./home/user
    '';

    config = {
      Entrypoint = [ "${pkgs.tini}/bin/tini" "--" ];
      Cmd = [ "${pkgs.openssh}/bin/sshd" "-D" "-e" ];
      ExposedPorts = {
        "22/tcp" = { };
      };
      Env = [
        "PATH=/bin:${pkgs.coreutils}/bin:${pkgs.openssh}/bin"
      ];
    };
  };
in
{
  configStorage = false;
  docker = {
    image = "landing:latest"; # Used for naming, but imageFile takes precedence
    imageFile = landingImage;
  };
}
