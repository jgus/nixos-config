{ pkgs, ... }:

{
  imports = [ ./docker.nix ];

  system.activationScripts = {
    docker-setup.text = ''
      ${pkgs.zfs}/bin/zfs list r/varlib/prowlarr >/dev/null 2>&1 || ( ${pkgs.zfs}/bin/zfs create r/varlib/prowlarr && chown josh:plex /var/lib/prowlarr )
    '';
  };

  networking.firewall = {
    allowedTCPPorts = [ 9696 ];
  };

  systemd = {
    services = {
      prowlarr = {
        enable = true;
        description = "Prowlarr";
        wantedBy = [ "multi-user.target" ];
        requires = [ "sabnzbd.service" "transmission.service" ];
        path = [ pkgs.docker ];
        script = ''
          docker container stop prowlarr >/dev/null 2>&1 || true ; \
          docker container rm -f prowlarr >/dev/null 2>&1 || true ; \
          docker run --rm --name prowlarr \
            -p 9696:9696 \
            -e PUID=$(id -u josh) \
            -e PGID=$(id -g plex) \
            -e TZ=$(timedatectl show -p Timezone --value) \
            -v /var/lib/prowlarr:/config \
            lscr.io/linuxserver/prowlarr
        '';
        serviceConfig = {
          Restart = "no";
        };
      };
      prowlarr-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull lscr.io/linuxserver/prowlarr | grep "Status: Downloaded"
          then
            systemctl restart prowlarr
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
