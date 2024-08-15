{ config, pkgs, lib, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  pw = import ./.secrets/passwords.nix;
  service = "zigbee2mqtt";
  image = "koenkk/zigbee2mqtt";
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
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
    ];
    environment = {
      TZ = config.time.timeZone;
    };
    ports = [
      "8081"
    ];
    volumes = [
      "/var/lib/${service}:/app/data"
    ];
  };

  systemd = {
    services = docker-services {
      name = "${service}";
      image = image;
      setup-script = ''
        if ! zfs list r/varlib/${service} >/dev/null 2>&1
        then
          zfs create r/varlib/${service}
          rsync -arPx --delete /nas/backup/varlib/${service}/ /var/lib/${service}/ || true
        fi
      '';
      backup-script = ''
        mkdir -p /nas/backup/varlib/${service}
        rsync -arPx --delete /var/lib/${service}/ /nas/backup/varlib/${service}/
      '';
    };
  };
}
