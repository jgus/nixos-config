{ pkgs, ... }:

{
  imports = [ ./docker.nix ];

  system.activationScripts = {
    docker-setup.text = ''
      ${pkgs.zfs}/bin/zfs list r/varlib/mylar >/dev/null 2>&1 || ( ${pkgs.zfs}/bin/zfs create r/varlib/mylar && chown josh:plex /var/lib/mylar )
    '';
  };

  networking.firewall = {
    allowedTCPPorts = [ 8090 ];
  };

  systemd = {
    services = {
      mylar = {
        enable = true;
        description = "Mylar";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        path = [ pkgs.docker ];
        script = ''
          docker container stop mylar >/dev/null 2>&1 || true ; \
          docker run --rm --name mylar \
            -p 8090:8090 \
            -e PUID=$(id -u josh) \
            -e PGID=$(id -g plex) \
            -e TZ=$(timedatectl show -p Timezone --value) \
            -v /var/lib/mylar:/config \
            -v /d/media/Comics:/comics \
            -v /d/scratch/peer:/peer \
            -v /d/scratch/usenet:/usenet \
            lscr.io/linuxserver/mylar3
          '';
        serviceConfig = {
          Restart = "always";
        };
      };
      mylar-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull lscr.io/linuxserver/mylar3 | grep "Status: Downloaded"
          then
            systemctl restart mylar
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
