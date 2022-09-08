{ pkgs, ... }:

{
  imports = [ ./docker.nix ];

  networking.firewall = {
    allowedTCPPorts = [ 9091 ];
  };

  systemd = {
    services = {
      transmission = {
        enable = true;
        description = "Transmission";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        path = [ pkgs.docker ];
        script = ''
          docker pull haugene/transmission-openvpn
          docker run --rm --name transmission \
            -p 9091:9091 \
            -e PUID=$(id -u josh) \
            -e PGID=$(id -g plex) \
            -e TZ=$(timedatectl show -p Timezone --value) \
            -e OPENVPN_PROVIDER=VPNAC \
            -e LOCAL_NETWORK=172.22.0.0/16 \
            -e TRANSMISSION_DOWNLOAD_DIR=/peer/Complete \
            -e TRANSMISSION_INCOMPLETE_DIR=/peer/Incomplete \
            -e TRANSMISSION_INCOMPLETE_DIR_ENABLED=true \
            -e TRANSMISSION_WATCH_DIR=/peer/Watch \
            -e TRANSMISSION_WATCH_DIR_ENABLED=true \
            --env-file /etc/nixos/.secrets/vpnac.env \
            --cap-add NET_ADMIN \
            -v /etc/localtime:/etc/localtime:ro \
            -v /var/lib/transmission:/data \
            -v /d/scratch/peer:/peer \
            haugene/transmission-openvpn
          '';
        serviceConfig = {
          Restart = "on-failure";
        };
      };
    };
  };
}
