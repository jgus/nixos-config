{ config, pkgs, ... }:

{
  imports = [ ./docker.nix ];

  system.activationScripts = {
    web-swag-setup.text = ''
      ${pkgs.zfs}/bin/zfs list r/varlib/esphome >/dev/null 2>&1 || ( ${pkgs.zfs}/bin/zfs create r/varlib/esphome && chown josh:users /var/lib/esphome )
    '';
  };

  networking.firewall.allowedTCPPorts = [ 6052 ];

  systemd = {
    services = {
      esphome = {
        enable = true;
        description = "ESPHome";
        wantedBy = [ "multi-user.target" ];
        requires = [ "docker.service" ];
        path = [ pkgs.docker ];
        script = ''
          docker container stop esphome >/dev/null 2>&1 || true ; \
          docker container rm -f esphome >/dev/null 2>&1 || true ; \
          docker run --rm --name esphome \
            --user "$(id -u josh)":"$(id -g josh)" \
            --net=host \
            -e PLATFORMIO_CORE_DIR=/cache/.plattformio \
            -e PLATFORMIO_GLOBALLIB_DIR=/cache/.plattformioLibs \
            -v /var/lib/esphome:/config \
            --tmpfs /cache:exec,uid=$(id -u josh),gid=$(id -g josh) \
            --tmpfs /config/.esphome/build:exec,uid=$(id -u josh),gid=$(id -g josh) \
            --tmpfs /config/.esphome/external_components:exec,uid=$(id -u josh),gid=$(id -g josh) \
            ghcr.io/esphome/esphome
          '';
      };
      esphome-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull ghcr.io/esphome/esphome | grep "Status: Downloaded"
          then
            systemctl restart esphome
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
