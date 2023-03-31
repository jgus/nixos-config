{ pkgs, ... }:

{
  imports = [ ./docker.nix ];

  system.activationScripts = {
    docker-setup.text = ''
      ${pkgs.zfs}/bin/zfs list r/varlib/komga >/dev/null 2>&1 || ( ${pkgs.zfs}/bin/zfs create r/varlib/komga && chown josh:plex /var/lib/komga )
    '';
  };

  networking.firewall = {
    allowedTCPPorts = [ 25600 ];
  };

  systemd = {
    services = {
      komga = {
        enable = true;
        description = "Komga";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        path = [ pkgs.docker ];
        script = ''
          docker container stop komga >/dev/null 2>&1 || true ; \
          docker run --rm --name komga \
            -p 25600:25600 \
            --user $(id -u josh):$(id -g plex) \
            -e TZ=$(timedatectl show -p Timezone --value) \
            -e SERVER_PORT=25600 \
            -v /var/lib/komga:/config \
            -v /d/media/Comics:/data \
            gotson/komga
          '';
        serviceConfig = {
          Restart = "always";
        };
      };
      komga-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull gotson/komga | grep "Status: Downloaded"
          then
            systemctl restart komga
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
