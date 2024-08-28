{ pkgs, config, ... }:
let
  user = "nathaniel";
  group = "users";
  name = "userbox-${user}";
  dockerfile = pkgs.writeText "Dockerfile" ''
    FROM alpine

    RUN apk add --no-cache openssh tini rsync nano
    RUN rm -rf /etc/ssh
    COPY entrypoint.sh /

    EXPOSE 22/tcp

    ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
    CMD []
  '';
  entrypoint = pkgs.writeText "entrypoint.sh" ''
    #!/bin/sh

    adduser -D ${user} -u ${toString config.users.users.${user}.uid}
    passwd -ud ${user}

    ssh-keygen -A

    /usr/sbin/sshd -D -e
  '';
  sshd_config = pkgs.writeText "sshd_config" ''
    PermitRootLogin no
    AuthorizedKeysFile .ssh/authorized_keys
    PasswordAuthentication no
    Subsystem sftp /usr/lib/ssh/sftp-server
  '';
in
{
  inherit name;
  requires = [ "home.mount" "storage-external.mount" ];
  systemd = {
    path = [ pkgs.docker pkgs.rsync ];
    script = { storagePath, dockerOptions, ... }: ''
      docker container stop ${name} >/dev/null 2>&1 || true
      docker container rm -f ${name} >/dev/null 2>&1 || true
      DIR=$(mktemp -d)
      cp ${dockerfile} ''${DIR}/Dockerfile
      cp ${entrypoint} ''${DIR}/entrypoint.sh
      chmod a+x ''${DIR}/entrypoint.sh
      docker build -t ${name} ''${DIR}
      rm -rf ''${DIR}
      /bin/sh -c "docker run --rm --name ${name} \
        ${builtins.concatStringsSep " " dockerOptions} \
        -p 22/tcp \
        -v /home/${user}:/home/${user} \
        -v /storage/external/${user}:/home/${user}/data \
        -v ${storagePath name}:/etc/ssh \
        -v ${sshd_config}:/etc/ssh/sshd_config \
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
    imports = [ ./../docker.nix ];
  };
}
