{ pkgs, ... }:

{
  imports = [ ./docker.nix ];

  networking.firewall.allowedTCPPorts = [ 22022 ];

  environment.etc = {
    "landing/docker/Dockerfile".text = ''
      FROM alpine

      RUN apk add --no-cache openssh tini
      RUN rm -rf /etc/ssh
      COPY entrypoint.sh /

      EXPOSE 22/tcp

      ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
      CMD []
    '';
    "landing/docker/entrypoint.sh".text = ''
      #!/bin/sh

      adduser -D user
      passwd -ud user
      mkdir /home/user/.ssh
      echo "''${AUTHORIZED_KEYS}" >/home/user/.ssh/authorized_keys
      chmod 700 /home/user/.ssh
      chmod 400 /home/user/.ssh/authorized_keys
      chown -R user:user /home/user/.ssh

      ssh-keygen -A

      /usr/sbin/sshd -D -e
    '';
    "landing/etc/ssh/sshd_config".text = ''
      PermitRootLogin no
      AuthorizedKeysFile .ssh/authorized_keys
      PasswordAuthentication no
      AllowTcpForwarding yes
      Subsystem sftp /usr/lib/ssh/sftp-server
    '';
  };

  systemd = {
    services = {
      landing = {
        enable = true;
        description = "Landing";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        path = [ pkgs.docker pkgs.rsync ];
        script = ''
          rsync -arPL /etc/landing /tmp/
          rsync -arPL /etc/nixos/.secrets/landing /tmp/
          chmod a+x /tmp/landing/docker/entrypoint.sh
          docker build -t ssh /tmp/landing/docker
          /bin/sh -c "docker run --rm --name landing \
            -p 22022:22/tcp \
            -e AUTHORIZED_KEYS='$(cat /root/.ssh/id_rsa-backup.pub)' \
            -v /tmp/landing/etc/ssh:/etc/ssh \
            ssh"
          '';
        unitConfig = {
          StartLimitIntervalSec = 0;
        };
        serviceConfig = {
          Restart = "always";
          RestartSec = 10;
        };
      };
    };
  };
}
