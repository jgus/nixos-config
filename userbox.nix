{ pkgs, config, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  user = "nathaniel";
  group = "users";
  name = "userbox-${user}";
in
{
  imports = [(homelabService {
    inherit name user group;
    requires = [ "home.mount" "nas.mount" ];
    systemd = {
      path = [ pkgs.docker pkgs.rsync ];
      script = { storagePath, dockerOptions, ... }: ''
        docker container stop ${name} >/dev/null 2>&1 || true ; \
        docker container rm -f ${name} >/dev/null 2>&1 || true ; \
        rsync -arPL /etc/${name} /tmp/
        chmod a+x /tmp/${name}/docker/entrypoint.sh
        docker build -t ${name} /tmp/${name}/docker
        /bin/sh -c "docker run --rm --name ${name} \
          ${builtins.concatStringsSep " " dockerOptions} \
          -p 22/tcp \
          -v /home/${user}:/home/${user} \
          -v /nas/external/${user}:/home/${user}/data \
          -v ${storagePath name}:/etc/ssh \
          -v /etc/${name}/etc/ssh/sshd_config:/etc/ssh/sshd_config \
          ${name}"
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
      environment.etc = {
        "${name}/docker/Dockerfile".text = ''
          FROM alpine

          RUN apk add --no-cache openssh tini rsync nano
          RUN rm -rf /etc/ssh
          COPY entrypoint.sh /

          EXPOSE 22/tcp

          ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
          CMD []
        '';
        "${name}/docker/entrypoint.sh".text = ''
          #!/bin/sh

          adduser -D ${user} -u ${toString config.users.users.${user}.uid}
          passwd -ud ${user}

          ssh-keygen -A

          /usr/sbin/sshd -D -e
        '';
        "${name}/etc/ssh/sshd_config".text = ''
          PermitRootLogin no
          AuthorizedKeysFile .ssh/authorized_keys
          PasswordAuthentication no
          Subsystem sftp /usr/lib/ssh/sftp-server
        '';
      };
    };
  })];
}
