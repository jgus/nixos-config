{ pkgs, ... }:

{
  imports = [ ./docker.nix ];

  system.activationScripts = {
    docker-setup.text = ''
      ${pkgs.zfs}/bin/zfs list r/varlib/lidarr >/dev/null 2>&1 || ( ${pkgs.zfs}/bin/zfs create r/varlib/lidarr && chown josh:plex /var/lib/lidarr )
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
        requires = [ "prowlarr.service" ];
        path = [ pkgs.docker ];
        script = ''
          docker container stop lidarr >/dev/null 2>&1 || true ; \
          docker container rm -f lidarr >/dev/null 2>&1 || true ; \
          docker run --rm --name lidarr \
            -p 8686:8686 \
            -e PUID=$(id -u josh) \
            -e PGID=$(id -g plex) \
            -e TZ=$(timedatectl show -p Timezone --value) \
            -v /var/lib/lidarr:/config \
            -v /d/scratch/peer:/peer \
            -v /d/scratch/usenet:/usenet \
            -v /d/media:/media \
            lscr.io/linuxserver/lidarr
        '';
        serviceConfig = {
          Restart = "always";
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
