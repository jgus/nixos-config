{ config, pkgs, ... }:

let
  devices = {
    pi-67cba1 = "/dev/serial/by-id/usb-Zooz_800_Z-Wave_Stick_533D004242-if00";
    pi-67db40 = "/dev/serial/by-id/usb-Zooz_800_Z-Wave_Stick_533D004242-if00";
    pi-67dbcd = "/dev/serial/by-id/usb-Zooz_800_Z-Wave_Stick_533D004242-if00";
    pi-67dc75 = "/dev/serial/by-id/usb-Zooz_800_Z-Wave_Stick_533D004242-if00";
  };
  image = "zwavejs/zwave-js-ui";
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

  virtualisation.oci-containers.containers.zwave-js-ui = {
    image = "${image}";
    autoStart = true;
    extraOptions = [
      "--device=${devices.${config.networking.hostName}}:/dev/zwave"
    ];
    ports = [
      "8091:8091"
      "3000:3000"
    ];
    environment = {
      TZ = "${config.time.timeZone}";
    };
    volumes = [
      "/var/lib/zwave-js-ui:/usr/src/app/store"
    ];
  };

  systemd = {
    services = {
      zwave-js-ui-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull ${image} | grep "Status: Downloaded"
          then
            systemctl restart docker-zwave-js-ui
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
