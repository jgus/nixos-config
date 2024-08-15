{ config, pkgs, area, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  service = "zwave-${area}";
  image = "zwavejs/zwave-js-ui";
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
  device = "/dev/serial/by-id/usb-Zooz_800_Z-Wave_Stick_533D004242-if00";
in
if (machine.hostName != addresses.records."${service}".host) then {} else
{
  imports = [ ./docker.nix ];

  virtualisation.oci-containers.containers."${service}" = {
    image = image;
    autoStart = true;
    extraOptions = [
      "--network=macvlan"
      "--mac-address=${addresses.records."${service}".mac}"
      "--ip=${addresses.records."${service}".ip}"
      "--device=${device}:/dev/zwave"
    ];
    ports = [
      "8091"
      "3000"
    ];
    environment = {
      TZ = config.time.timeZone;
    };
    volumes = [
      "/var/lib/${service}:/usr/src/app/store"
    ];
  };

  systemd = {
    services = docker-services {
      name = service;
      image = image;
      setup-script = ''
        if ! [ -d /var/lib/${service} ] >/dev/null 2>&1
        then
          mkdir /var/lib/${service}
          rsync -arPx --delete /nas/backup/varlib/${service}/ mkdir /var/lib/${service}/ || true
        fi
      '';
      backup-script = ''
        mkdir -p /nas/backup/varlib/${service}
        rsync -arPx --delete /var/lib/${service}/ /nas/backup/varlib/${service}/
      '';
    };
  };
}
