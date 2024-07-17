{ pkgs, ... }:

let
  user = "nathaniel";
  uid = 1023;
  port = 22023;
in
{
  imports = [ ./docker.nix ];

  users.users.${user} = {
    uid = uid;
    isNormalUser = true;
  };

  networking.firewall.allowedTCPPorts = [ port ];

  environment.etc = {
    "userbox-${user}/docker/Dockerfile".text = ''
      FROM alpine

      RUN apk add --no-cache openssh tini rsync nano
      RUN rm -rf /etc/ssh
      COPY entrypoint.sh /

      EXPOSE 22/tcp

      ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
      CMD []
    '';
    "userbox-${user}/docker/entrypoint.sh".text = ''
      #!/bin/sh

      adduser -D ${user} -u ${toString uid}
      passwd -ud ${user}

      ssh-keygen -A

      /usr/sbin/sshd -D -e
    '';
    "userbox-${user}/etc/ssh/sshd_config".text = ''
      PermitRootLogin no
      AuthorizedKeysFile .ssh/authorized_keys
      PasswordAuthentication no
      Subsystem sftp /usr/lib/ssh/sftp-server
    '';
  };

  systemd = {
    services = {
      "userbox-${user}" = {
        enable = true;
        description = "userbox-${user}";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        path = [ pkgs.docker pkgs.rsync ];
        script = ''
          docker container stop userbox-${user} >/dev/null 2>&1 || true ; \
          docker container rm -f userbox-${user} >/dev/null 2>&1 || true ; \
          rsync -arPL /etc/userbox-${user} /tmp/
          chmod a+x /tmp/userbox-${user}/docker/entrypoint.sh
          docker build -t userbox-${user} /tmp/userbox-${user}/docker
          /bin/sh -c "docker run --rm --name userbox-${user} \
            -p ${toString port}:22/tcp \
            -v /home/${user}:/home/${user} \
            -v /d/external/${user}:/home/${user}/data \
            -v /var/lib/userbox-${user}:/etc/ssh \
            -v /etc/userbox-${user}/etc/ssh/sshd_config:/etc/ssh/sshd_config \
            userbox-${user}"
        '';
        unitConfig = {
          StartLimitIntervalSec = 0;
        };
        serviceConfig = {
          Restart = "no";
          RestartSec = 10;
        };
      };
    };
  };
}
