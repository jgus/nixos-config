{ pkgs, ... }:

{
  imports = [ ./docker.nix ];

  system.activationScripts = {
    docker-setup.text = ''
      ${pkgs.zfs}/bin/zfs list d/varlib/lidarr >/dev/null 2>&1 || ( ${pkgs.zfs}/bin/zfs create d/varlib/lidarr && chown josh:plex /var/lib/lidarr )
    '';
  };

  networking.firewall = {
    allowedTCPPorts = [ 8686 ];
  };

  systemd = {
    services = {
      lidarr = {
        enable = true;
        description = "Lidarr";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        path = [ pkgs.docker ];
        script = ''
          docker run --rm --name lidarr \
            -p 8686:8686 \
            -e PUID=$(id -u josh) \
            -e PGID=$(id -g plex) \
            -e TZ=$(timedatectl show -p Timezone --value) \
            -v /var/lib/lidarr:/config \
            -v /d/scratch/peer:/peer \
            -v /d/media:/media \
            lscr.io/linuxserver/lidarr
          '';
        serviceConfig = {
          Restart = "on-failure";
        };
      };
      lidarr-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull lscr.io/linuxserver/lidarr | grep "Status: Downloaded"
          then
            systemctl restart lidarr
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
