{ config, pkgs, ... }:

{
  imports = [ ./docker.nix ];

  system.activationScripts = {
    web-swag-setup.text = ''
      ${pkgs.zfs}/bin/zfs list r/varlib/home-assistant-record >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create r/varlib/home-assistant-record
    '';
  };

  systemd = {
    services = {
      home-assistant-record = {
        enable = true;
        description = "Home Assistant Record DB";
        wantedBy = [ "multi-user.target" ];
        requires = [ "docker.service" ];
        path = [ pkgs.docker ];
        script = ''
          docker container stop home-assistant-record >/dev/null 2>&1 || true ; \
          docker container rm -f home-assistant-record >/dev/null 2>&1 || true ; \
          docker run --rm --name home-assistant-record \
            --env-file /etc/nixos/.secrets/home-assistant-record.env \
            -e MARIADB_AUTO_UPGRADE=yes \
            -e MARIADB_DISABLE_UPGRADE_BACKUP=yes \
            -p 13306:3306 \
            -v /var/lib/home-assistant-record:/var/lib/mysql \
            mariadb:latest
          '';
      };
      home-assistant-record-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull mariadb:latest | grep "Status: Downloaded"
          then
            systemctl restart home-assistant-record
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
