{ config, pkgs, ... }:

let
  devices = {
    pi-67cba1 = "/dev/serial/by-id/usb-Zooz_800_Z-Wave_Stick_533D004242-if00";
    pi-67db40 = "/dev/serial/by-id/usb-Zooz_800_Z-Wave_Stick_533D004242-if00";
    pi-67dbcd = "/dev/serial/by-id/usb-Zooz_800_Z-Wave_Stick_533D004242-if00";
    pi-67dc75 = "/dev/serial/by-id/usb-Zooz_800_Z-Wave_Stick_533D004242-if00";
  };
in
{
  imports = [ ./docker.nix ];

  system.activationScripts = {
    zwave-js-ui-setup.text = ''
      [ -d /var/lib/zwave-js-ui ] || ( mkdir /var/lib/zwave-js-ui )
    '';
  };

  networking.firewall = {
    allowedTCPPorts = [ 8091 3000 ];
  };

  systemd = {
    services = {
      zwave-js-ui = {
        enable = true;
        description = "ZWave-JS-UI";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        path = [ pkgs.docker ];
        script = ''
          docker container stop zwave-js-ui >/dev/null 2>&1 || true ; \
          docker run --rm --name zwave-js-ui \
            -p 8091:8091 \
            -p 3000:3000 \
            --device=${devices.${config.networking.hostName}}:/dev/zwave \
            -e TZ=$(timedatectl show -p Timezone --value) \
            -v /var/lib/zwave-js-ui:/usr/src/app/store \
            zwavejs/zwave-js-ui
          '';
        serviceConfig = {
          Restart = "no";
        };
      };
      zwave-js-ui-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull zwavejs/zwave-js-ui | grep "Status: Downloaded"
          then
            systemctl restart zwave-js-ui
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
