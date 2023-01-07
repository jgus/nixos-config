{ pkgs, ... }:

{
  imports = [ ./docker.nix ];

  system.activationScripts = {
    docker-setup.text = ''
      ${pkgs.zfs}/bin/zfs list s/varlib/sabnzbd >/dev/null 2>&1 || ( ${pkgs.zfs}/bin/zfs create s/varlib/sabnzbd && chown josh:plex /var/lib/sabnzbd )
    '';
  };

  networking.firewall = {
    allowedTCPPorts = [ 8080 ];
  };

  systemd = {
    services = {
      sabnzbd = {
        enable = true;
        description = "Sabnzbd";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        path = [ pkgs.docker ];
        script = ''
          docker run --rm --name sabnzbd \
            -p 8080:8080 \
            -e PUID=$(id -u josh) \
            -e PGID=$(id -g plex) \
            -e TZ=$(timedatectl show -p Timezone --value) \
            -v /var/lib/sabnzbd:/config \
            -v /d/scratch/usenet:/config/Downloads \
            lscr.io/linuxserver/sabnzbd
          '';
        serviceConfig = {
          Restart = "always";
        };
      };
      sabnzbd-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull lscr.io/linuxserver/sabnzbd | grep "Status: Downloaded"
          then
            systemctl restart sabnzbd
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
