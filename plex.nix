{ config, pkgs, ... }:

{
  imports = [ ./docker.nix ];

  users = {
    groups.plex = { gid = 193; };
    users.plex = {
      uid = 193;
      isSystemUser = true;
      group = "plex";
    };
  };

  system.activationScripts = {
    plexSetup.text = ''
      ${pkgs.zfs}/bin/zfs list r/varlib/plex >/dev/null 2>&1 || ( ${pkgs.zfs}/bin/zfs create r/varlib/plex && chown plex:plex /var/lib/plex )
    '';
  };

  networking.firewall.allowedTCPPorts = [ 32400 ];

  systemd = {
    services = {
      plex = {
        enable = true;
        description = "Plex Media Server";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        path = [ pkgs.docker ];
        script = ''
          docker container stop plex >/dev/null 2>&1 || true ; \
          docker container rm -f plex >/dev/null 2>&1 || true ; \
          docker run --rm --name plex \
            --net host \
            --gpus all \
            --device /dev/dri:/dev/dri \
            -e PUID="$(id -u plex)" \
            -e PGID="$(id -g plex)" \
            -e TZ="$(timedatectl show -p Timezone --value)" \
            -e VERSION=latest \
            -v /var/lib/plex:/config \
            -v /d/media:/media \
            -v /d/photos:/shares/photos \
            --tmpfs /tmp \
            lscr.io/linuxserver/plex
          '';
        serviceConfig = {
          Restart = "on-failure";
        };
      };
      plex-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull lscr.io/linuxserver/plex | grep "Status: Downloaded"
          then
            systemctl restart plex
          fi
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        startAt = "hourly";
      };
    };
  };
}
