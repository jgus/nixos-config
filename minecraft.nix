{ pkgs, lib, ... }:

{
  imports = [ ./docker.nix ];

  networking.firewall.allowedTCPPorts = [
    25522
    8123
    19132
    19133
    25565
    25565
  ];

  users = {
    groups.minecraft = { gid = 996; };
    users.minecraft = {
      uid = 998;
      isSystemUser = true;
      group = "minecraft";
    };
  };

  environment.etc =
    lib.attrsets.mapAttrs'
      (name: value:
        lib.attrsets.nameValuePair
          ("minecraft/docker/${name}")
          {
            source = ./minecraft/docker/${name};
            mode = "0444";
          }
      )
      (builtins.readDir ./minecraft/docker);

  systemd = {
    services = {
      minecraft = {
        enable = true;
        description = "Minecraft";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        path = [ pkgs.docker pkgs.zfs ];
        script = ''
          zfs list rpool/varlib/minecraft >/dev/null 2>&1 || ( zfs create rpool/varlib/minecraft && chown minecraft:minecraft /var/lib/minecraft )

          docker build \
            --build-arg uid=$(id -u minecraft) \
            --build-arg gid=$(id -g minecraft) \
            --build-arg java_ver=17 \
            -t minecraft \
            /etc/minecraft/docker

          docker run --rm --name minecraft \
            -p 25522:22/tcp \
            -p 8123:8123/tcp \
            -p 19132:19132/udp \
            -p 19133:19133/udp \
            -p 25565:25565/udp \
            -p 25565:25565/tcp \
            -v /var/volumes/minecraft_config:/home/minecraft/config \
            minecraft
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
