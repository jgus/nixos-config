{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  machine = import ./machine.nix;
  device = {
    pi-67cba1 = "/dev/serial/by-id/usb-Zooz_800_Z-Wave_Stick_533D004242-if00";
    pi-67db40 = "/dev/serial/by-id/usb-Zooz_800_Z-Wave_Stick_533D004242-if00";
    pi-67dbcd = "/dev/serial/by-id/usb-Zooz_800_Z-Wave_Stick_533D004242-if00";
    pi-67dc75 = "/dev/serial/by-id/usb-Zooz_800_Z-Wave_Stick_533D004242-if00";
  }."${machine.hostName}";
  image = "zwavejs/zwave-js-ui";
in
{
  imports = [ ./docker.nix ];

  networking.firewall = {
    allowedTCPPorts = [ 8091 3000 ];
  };

  virtualisation.oci-containers.containers.zwave-js-ui = {
    image = "${image}";
    autoStart = true;
    extraOptions = [
      "--device=${device}:/dev/zwave"
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
    services = docker-services {
      name = "zwave-js-ui";
      image = image;
      setup-script = ''
        if ! [ -d /var/lib/zwave-js-ui ] >/dev/null 2>&1
        then
          mkdir /var/lib/zwave-js-ui
          rsync -arPx --delete /nas/backup/varlib/zwave-js-ui-${machine.hostName}/ mkdir /var/lib/zwave-js-ui/ || true
        fi
      '';
      backup-script = ''
        mkdir -p /nas/backup/varlib/zwave-js-ui-${machine.hostName}
        rsync -arPx --delete /var/lib/zwave-js-ui/ /nas/backup/varlib/zwave-js-ui-${machine.hostName}/
      '';
    };
  };
}
