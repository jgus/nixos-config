{ config, pkgs, ... }:

let
  service = "mosquitto";
  user = "mosquitto";
  group = "mosquitto";
  pw = import ./.secrets/passwords.nix;
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
in
if (machine.hostName != addresses.services."${service}".host) then {} else
{
  networking = {
    macvlans."eth-${service}" = {
      interface = "br0";
    };
    interfaces."eth-${service}" = {
      macAddress = addresses.services.${service}.mac;
      useDHCP = true;
      #ipv4.addresses = [ { address = addresses.services.${service}.ip; prefixLength = 16; } ];
    };
    firewall = {
      allowedTCPPorts = [ 1883 ];
    };
  };

  services."${service}" = {
    enable = true;
    dataDir = "/var/lib/${service}";
    # logType = [ "all" ];
    listeners = [
      {
        address = addresses.services.${service}.ip;
        users = {
          ha = {
            acl = [ "readwrite #" ];
            password = "${pw.mqtt.ha}";
          };
          frigate = {
            acl = [ "readwrite #" ];
            password = "${pw.mqtt.frigate}";
          };
          zigbee2mqtt = {
            acl = [ "readwrite #" ];
            password = "${pw.mqtt.zigbee2mqtt}";
          };
          theater_remote = {
            acl = [ "readwrite #" ];
            password = "${pw.mqtt.theater_remote}";
          };
          frodo = {
            acl = [ "readwrite valetudo/Frodo/#" ];
            password = "${pw.mqtt.frodo}";
          };
          sam = {
            acl = [ "readwrite valetudo/Sam/#" ];
            password = "${pw.mqtt.sam}";
          };
          merry = {
            acl = [ "readwrite valetudo/Merry/#" ];
            password = "${pw.mqtt.merry}";
          };
          pippin = {
            acl = [ "readwrite valetudo/Pippin/#" ];
            password = "${pw.mqtt.pippin}";
          };
        };
      }
    ];
  };

  systemd = {
    services = {
      "${service}-setup" = {
        path = [ pkgs.zfs ];
        script = ''
          zfs list r/varlib/${service} >/dev/null 2>&1 || ( zfs create r/varlib/${service} && chown ${user}:${group} /var/lib/${service} )
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        requiredBy = [ "${service}.service" ];
        before = [ "${service}.service" ];
      };
      "${service}-kick" = {
        enable = true;
        description = "Restart Mosquitto after network address is available";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-addresses-eth-${service}.service" ];
        script = ''
          while ! systemctl restart ${service}.service
          do
            sleep 1
            systemctl stop ${service}.service || true
          done
        '';
        serviceConfig = {
          Type = "oneshot";
        };
      };
    };
  };
}
