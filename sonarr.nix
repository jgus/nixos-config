{ pkgs, ... }:

{
  imports = [ ./docker.nix ];

  system.activationScripts = {
    docker-setup.text = ''
      ${pkgs.zfs}/bin/zfs list r/varlib/sonarr >/dev/null 2>&1 || ( ${pkgs.zfs}/bin/zfs create r/varlib/sonarr && chown josh:plex /var/lib/sonarr )
    '';
  };

  networking.firewall = {
    allowedTCPPorts = [ 8989 ];
  };

  systemd = {
    services = {
      sonarr = {
        enable = true;
        description = "Sonarr";
        wantedBy = [ "multi-user.target" ];
        requires = [ "prowlarr.service" ];
        path = [ pkgs.docker ];
        script = ''
          docker container stop sonarr >/dev/null 2>&1 || true ; \
          docker container rm -f sonarr >/dev/null 2>&1 || true ; \
          docker run --rm --name sonarr \
            -p 8989:8989 \
            -e PUID=$(id -u josh) \
            -e PGID=$(id -g plex) \
            -e TZ=$(timedatectl show -p Timezone --value) \
            -v /var/lib/sonarr:/config \
            -v /d/scratch/peer:/peer \
            -v /d/scratch/usenet:/usenet \
            -v /d/media:/media \
            lscr.io/linuxserver/sonarr
        '';
        serviceConfig = {
          Restart = "always";
        };
      };
      sonarr-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull lscr.io/linuxserver/sonarr | grep "Status: Downloaded"
          then
            systemctl restart sonarr
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
