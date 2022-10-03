{ pkgs, ... }:

{
  imports = [ ./docker.nix ];

  system.activationScripts = {
    docker-setup.text = ''
      ${pkgs.zfs}/bin/zfs list d/varlib/radarr >/dev/null 2>&1 || ( ${pkgs.zfs}/bin/zfs create d/varlib/radarr && chown josh:plex /var/lib/radarr )
    '';
  };

  networking.firewall = {
    allowedTCPPorts = [ 7878 ];
  };

  systemd = {
    services = {
      radarr = {
        enable = true;
        description = "Radarr";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        path = [ pkgs.docker ];
        script = ''
          docker pull lscr.io/linuxserver/radarr
          docker run --rm --name radarr \
            -p 7878:7878 \
            -e PUID=$(id -u josh) \
            -e PGID=$(id -g plex) \
            -e TZ=$(timedatectl show -p Timezone --value) \
            -v /var/lib/radarr:/config \
            -v /d/scratch/peer:/peer \
            -v /d/media:/media \
            lscr.io/linuxserver/radarr
          '';
        serviceConfig = {
          Restart = "on-failure";
        };
      };
    };
  };
}
