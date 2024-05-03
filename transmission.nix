{ pkgs, ... }:

{
  imports = [ ./docker.nix ];

  networking.firewall = {
    allowedTCPPorts = [ 9091 51413 ];
    allowedUDPPorts = [ 9091 51413 ];
  };

  system.activationScripts = {
    transmissionSetup.text = ''
      ${pkgs.zfs}/bin/zfs list r/varlib/transmission >/dev/null 2>&1 || ( ${pkgs.zfs}/bin/zfs create r/varlib/transmission && chown josh:plex /var/lib/transmission )
    '';
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
          docker container stop transmission >/dev/null 2>&1 || true ; \
          docker container rm -f transmission >/dev/null 2>&1 || true ; \
          docker run --rm --name transmission \
            -p 9091:9091 \
            -p 51413:51413 \
            -e PUID=$(id -u josh) \
            -e PGID=$(id -g plex) \
            -e TZ=$(timedatectl show -p Timezone --value) \
            -e OPENVPN_PROVIDER=PRIVADO \
            -e LOCAL_NETWORK=172.22.0.0/16,192.168.2.0/24 \
            -e TRANSMISSION_DOWNLOAD_DIR=/peer/Complete \
            -e TRANSMISSION_INCOMPLETE_DIR=/peer/Incomplete \
            -e TRANSMISSION_INCOMPLETE_DIR_ENABLED=true \
            -e TRANSMISSION_WATCH_DIR=/peer/Watch \
            -e TRANSMISSION_WATCH_DIR_ENABLED=true \
            -e TRANSMISSION_DOWNLOAD_QUEUE_ENABLED=false \
            -e TRANSMISSION_BLOCKLIST_ENABLED=true \
            -e TRANSMISSION_BLOCKLIST_URL="https://github.com/Naunter/BT_BlockLists/raw/master/bt_blocklists.gz" \
            --env-file /etc/nixos/.secrets/privadovpn.env \
            --cap-add NET_ADMIN \
            -v /etc/localtime:/etc/localtime:ro \
            -v /var/lib/transmission:/data \
            -v /d/scratch/peer:/peer \
            haugene/transmission-openvpn
        '';
        serviceConfig = {
          Restart = "no";
        };
      };
      transmission-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull haugene/transmission-openvpn | grep "Status: Downloaded"
          then
            systemctl restart transmission
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
