{ pkgs, ... }:

let
  user = "nathaniel";
  uid = 1023;
  service = "userbox-${user}";
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
in
if (machine.hostName != addresses.records."${service}".host) then {} else
{
  imports = [ ./docker.nix ];

  users.users."${user}" = {
    uid = uid;
    isNormalUser = true;
  };

  environment.etc = {
    "${service}/docker/Dockerfile".text = ''
      FROM alpine

      RUN apk add --no-cache openssh tini rsync nano
      RUN rm -rf /etc/ssh
      COPY entrypoint.sh /

      EXPOSE 22/tcp

      ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
      CMD []
    '';
    "${service}/docker/entrypoint.sh".text = ''
      #!/bin/sh

      adduser -D ${user} -u ${toString uid}
      passwd -ud ${user}

      ssh-keygen -A

      /usr/sbin/sshd -D -e
    '';
    "${service}/etc/ssh/sshd_config".text = ''
      PermitRootLogin no
      AuthorizedKeysFile .ssh/authorized_keys
      PasswordAuthentication no
      Subsystem sftp /usr/lib/ssh/sftp-server
    '';
  };

  systemd = {
    services = {
      "${service}" = {
        enable = true;
        description = service;
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        path = [ pkgs.docker pkgs.rsync ];
        script = ''
          docker container stop ${service} >/dev/null 2>&1 || true ; \
          docker container rm -f ${service} >/dev/null 2>&1 || true ; \
          rsync -arPL /etc/${service} /tmp/
          chmod a+x /tmp/${service}/docker/entrypoint.sh
          docker build -t ${service} /tmp/${service}/docker
          /bin/sh -c "docker run --rm --name ${service} \
            ${builtins.concatStringsSep " " (addresses.dockerOptions service)} \
            -p 22/tcp \
            -v /home/${user}:/home/${user} \
            -v /nas/external/${user}:/home/${user}/data \
            -v /var/lib/${service}:/etc/ssh \
            -v /etc/${service}/etc/ssh/sshd_config:/etc/ssh/sshd_config \
            ${service}"
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
