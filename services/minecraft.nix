let
  name = "minecraft";
  user = "minecraft";
  group = "minecraft";
in
{ config, pkgs, ... }:
{
  systemd = {
    path = [ pkgs.docker pkgs.zfs ];
    script = { storagePath, dockerOptions, ... }: ''
      docker container stop ${name} >/dev/null 2>&1 || true ; \
      docker container rm -f ${name} >/dev/null 2>&1 || true ; \

      docker build \
        --build-arg uid=${toString config.users.users.${user}.uid} \
        --build-arg gid=${toString config.users.groups.${group}.gid} \
        --build-arg java_ver=21 \
        -t ${name} \
        ${./minecraft/docker}

      docker run --rm --name ${name} \
        ${builtins.concatStringsSep " " dockerOptions} \
        -p 22/tcp \
        -p 19132/udp \
        -p 19133/udp \
        -p 25565/udp \
        -p 25565/tcp \
        -p 8123/tcp \
        -v ${storagePath name}:/home/${name}/config \
        ${name}
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
