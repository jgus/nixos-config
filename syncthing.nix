{ pkgs, ... }:

{
  imports = [ ./docker.nix ];

  networking.firewall = {
    allowedTCPPorts = [ 8384 22000 ];
    allowedUDPPorts = [ 21027 ];
  };

  systemd = {
    services = {
      syncthing = {
        enable = true;
        description = "Syncthing";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        path = [ pkgs.docker ];
        script = ''
          docker pull lscr.io/linuxserver/syncthing
          docker run --rm --name syncthing \
            -p 8384:8384 \
            -p 22000:22000 \
            -p 21027:21027/udp \
            -e PUID=$(id -u josh) \
            -e PGID=$(id -g josh) \
            -e TZ=$(timedatectl show -p Timezone --value) \
            -e UMASK_SET=002 \
            -v /var/lib/syncthing:/config \
            -v /home/josh/sync:/shares/Sync \
            -v /d/photos:/shares/Photos \
            -v /d/software/Tools:/shares/Tools \
            -v /d/media/Comics:/shares/Comics \
            -v /d/media/Music:/shares/Music \
            lscr.io/linuxserver/syncthing
          '';
        serviceConfig = {
          Restart = "on-failure";
        };
      };
    };
  };
}
