{ config, pkgs, lib, ... }:

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
    services = {
      zigbee2mqtt-setup = {
        path = [ pkgs.zfs ];
        script = ''
          zfs list r/varlib/zigbee2mqtt >/dev/null 2>&1 || ( zfs create r/varlib/zigbee2mqtt )
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        requiredBy = [ "docker-zigbee2mqtt.service" ];
        before = [ "docker-zigbee2mqtt.service" ];
      };
      zigbee2mqtt-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull ${image} | grep "Status: Downloaded"
          then
            systemctl restart docker-zigbee2mqtt
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
