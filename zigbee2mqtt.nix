{ config, pkgs, lib, ... }:

let
  pw = import ./.secrets/passwords.nix;
  image = "koenkk/zigbee2mqtt";
in
{
  imports = [ ./docker.nix ];

  system.activationScripts = {
    zigbee2mqttSetup.text = ''
      ${pkgs.zfs}/bin/zfs list r/varlib/zigbee2mqtt >/dev/null 2>&1 || ( ${pkgs.zfs}/bin/zfs create r/varlib/zigbee2mqtt )
    '';
  };

  networking.firewall.allowedTCPPorts = [ 8081 ];

  systemd = {
    services = {
      zigbee2mqtt = {
        enable = true;
        description = "Zigbee2mqtt";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        path = [ pkgs.docker ];
        script = ''
          docker container stop zigbee2mqtt >/dev/null 2>&1 || true ; \
          docker container rm -f zigbee2mqtt >/dev/null 2>&1 || true ; \
          docker run --rm --name zigbee2mqtt \
            -e TZ="$(timedatectl show -p Timezone --value)" \
            -p 8081:8081 \
            -v /var/lib/zigbee2mqtt:/app/data \
            ${image}
        '';
        serviceConfig = {
          Restart = "no";
        };
      };
      zigbee2mqtt-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull ${image} | grep "Status: Downloaded"
          then
            systemctl restart zigbee2mqtt
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
