{ pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  pubkeys = import ./pubkeys.nix;
  dockerfile = pkgs.writeText "Dockerfile" ''
    FROM alpine

    RUN apk add --no-cache openssh tini
    RUN rm -rf /etc/ssh
    COPY entrypoint.sh /

    EXPOSE 22/tcp

    ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
    CMD []
  '';
  entrypoint = pkgs.writeText "entrypoint.sh" ''
    #!/bin/sh

    adduser -D user
    passwd -ud user
    mkdir /home/user/.ssh
    echo "${pubkeys.backup-rsa}" >/home/user/.ssh/authorized_keys
    chmod 700 /home/user/.ssh
    chmod 400 /home/user/.ssh/authorized_keys
    chown -R user:user /home/user/.ssh

    ssh-keygen -A

    /usr/sbin/sshd -D -e
  '';
  sshd_config = pkgs.writeText "sshd_config" ''
    PermitRootLogin no
    AuthorizedKeysFile .ssh/authorized_keys
    PasswordAuthentication no
    AllowTcpForwarding yes
    Subsystem sftp /usr/lib/ssh/sftp-server
  '';
in
{
  imports = [(homelabService {
    name = "landing";
    configStorage = false;
    systemd = {
      path = [ pkgs.docker pkgs.rsync ];
      script = { dockerOptions, ... }: ''
        docker container stop landing >/dev/null 2>&1 || true ; \
        docker container rm -f landing >/dev/null 2>&1 || true ; \
        BUILD_DIR=$(mktemp -d)
        cp ${dockerfile} ''${BUILD_DIR}/Dockerfile
        cp ${entrypoint} ''${BUILD_DIR}/entrypoint.sh
        chmod a+x ''${BUILD_DIR}/entrypoint.sh
        docker build -t landing ''${BUILD_DIR}
        rm -rf ''${BUILD_DIR}
        SSH_DIR=$(mktemp -d)
        rsync -arPL ${./.secrets/landing/etc/ssh}/ ''${SSH_DIR}/
        cp ${sshd_config} ''${SSH_DIR}/sshd_config
        chmod -R 400 ''${SSH_DIR}
        /bin/sh -c "docker run --rm --name landing \
          ${builtins.concatStringsSep " " dockerOptions} \
          -v ''${SSH_DIR}:/etc/ssh \
          landing"
        rm -rf ''${SSH_DIR}
      '';
      unitConfig = {
        StartLimitIntervalSec = 0;
      };
      serviceConfig = {
        Restart = "no";
        RestartSec = 10;
      };
    };
    extraConfig = {
      imports = [ ./docker.nix ];
    };
  })];
}
