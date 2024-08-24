{ config, pkgs, lib, ... }:

with builtins;
with (import ./functions.nix) { inherit pkgs; };
let
  name = "minecraft";
  user = "minecraft";
  group = "minecraft";
in
{
  imports = [(homelabService {
    inherit name;
    systemd = {
      path = [ pkgs.docker pkgs.zfs ];
      script = { uid, gid, storagePath, dockerOptions, ... }: ''
        docker container stop ${name} >/dev/null 2>&1 || true ; \
        docker container rm -f ${name} >/dev/null 2>&1 || true ; \

        docker build \
          --build-arg uid=${uid} \
          --build-arg gid=${gid} \
          --build-arg java_ver=21 \
          -t ${name} \
          /etc/${name}/docker

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
      imports = [ ./docker.nix ];
      environment.etc =
        lib.attrsets.mapAttrs'
          (key: value:
            lib.attrsets.nameValuePair
              ("${name}/docker/${key}")
              {
                source = ./${name}/docker/${key};
                mode = "0444";
              }
          )
          (builtins.readDir ./${name}/docker);
    };
  })];
}
