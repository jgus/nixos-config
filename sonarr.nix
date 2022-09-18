{ pkgs, ... }:

{
  imports = [ ./docker.nix ];

  networking.firewall = {
    allowedTCPPorts = [ 8989 ];
  };

  systemd = {
    services = {
      sonarr = {
        enable = true;
        description = "Sonarr";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        path = [ pkgs.docker ];
        script = ''
          docker pull lscr.io/linuxserver/sonarr
          docker run --rm --name sonarr \
            -p 8989:8989 \
            -e PUID=$(id -u josh) \
            -e PGID=$(id -g plex) \
            -e TZ=$(timedatectl show -p Timezone --value) \
            -v /var/lib/sonarr:/config \
            -v /d/scratch/peer:/peer \
            -v /d/media:/media \
            lscr.io/linuxserver/sonarr
          '';
        serviceConfig = {
          Restart = "on-failure";
        };
      };
    };
  };
}
