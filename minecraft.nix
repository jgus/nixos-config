{ config, pkgs, lib, ... }:

let
  service = "minecraft";
  serviceMount = "var-lib-${builtins.replaceStrings ["-"] ["\\x2d"] service}.mount";
  user = "minecraft";
  group = "minecraft";
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
in
if (machine.hostName != addresses.records."${service}".host) then {} else
{
  imports = [ ./docker.nix ];

  environment.etc =
    lib.attrsets.mapAttrs'
      (name: value:
        lib.attrsets.nameValuePair
          ("${service}/docker/${name}")
          {
            source = ./${service}/docker/${name};
            mode = "0444";
          }
      )
      (builtins.readDir ./${service}/docker);

  fileSystems."/var/lib/${service}" = {
    device = "localhost:/varlib-${service}";
    fsType = "glusterfs";
  };

  systemd = {
    services = {
      "${service}" = {
        enable = true;
        description = "Minecraft";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" serviceMount ];
        path = [ pkgs.docker pkgs.zfs ];
        script = ''
          zfs list r/varlib/${service} >/dev/null 2>&1 || ( zfs create r/varlib/${service} && chown ${user}:${group} /var/lib/${service} )

          docker container stop ${service} >/dev/null 2>&1 || true ; \
          docker container rm -f ${service} >/dev/null 2>&1 || true ; \

          docker build \
            --build-arg uid=${toString config.users.users."${user}".uid} \
            --build-arg gid=${toString config.users.groups."${group}".gid} \
            --build-arg java_ver=21 \
            -t ${service} \
            /etc/${service}/docker

          docker run --rm --name ${service} \
            ${builtins.concatStringsSep " " (addresses.dockerOptions service)} \
            -p 22/tcp \
            -p 19132/udp \
            -p 19133/udp \
            -p 25565/udp \
            -p 25565/tcp \
            -p 8123/tcp \
            -v /var/lib/${service}:/home/${service}/config \
            ${service}
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
