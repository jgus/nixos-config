{ config, pkgs, lib, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  pw = import ./.secrets/passwords.nix;
  image = "koenkk/zigbee2mqtt";
in
{
  imports = [ ./docker.nix ];

  networking.firewall.allowedTCPPorts = [ 8081 ];

  virtualisation.oci-containers.containers.zigbee2mqtt = {
    image = "${image}";
    autoStart = true;
    environment = {
      TZ = "${config.time.timeZone}";
    };
    ports = [
      "8081:8081"
    ];
    volumes = [
      "/var/lib/zigbee2mqtt:/app/data"
    ];
  };

  systemd = {
    services = docker-services {
      name = "zigbee2mqtt";
      image = image;
      setup-script = ''
        if ! zfs list r/varlib/zigbee2mqtt >/dev/null 2>&1
        then
          zfs create r/varlib/zigbee2mqtt
          rsync -arPx --delete /nas/backup/varlib/zigbee2mqtt/ /var/lib/zigbee2mqtt/ || true
        fi
      '';
      backup-script = ''
        mkdir -p /nas/backup/varlib/zigbee2mqtt
        rsync -arPx --delete /var/lib/zigbee2mqtt/ /nas/backup/varlib/zigbee2mqtt/
      '';
    };
  };
}
