{ config, pkgs, ... }:

let
  pw = import ./.secrets/passwords.nix;
  addresses = import ./addresses.nix;
in
{

  networking = {
    macvlans.br-mqtt = {
      interface = "br0";
    };
    interfaces.br-mqtt = {
      macAddress = addresses.services.mqtt.mac;
      useDHCP = true;
      #ipv4.addresses = [ { address = addresses.services.mqtt.ip; prefixLength = 16; } ];
    };
    firewall = {
      allowedTCPPorts = [ 1883 ];
    };
  };

  services.mosquitto = {
    enable = true;
    dataDir = "/var/lib/mosquitto";
    # logType = [ "all" ];
    listeners = [
      {
        address = addresses.services.mqtt.ip;
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
      mosquitto-setup = {
        path = [ pkgs.zfs ];
        script = ''
          zfs list r/varlib/mosquitto >/dev/null 2>&1 || ( zfs create r/varlib/mosquitto && chown mosquitto:mosquitto /var/lib/mosquitto )
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        requiredBy = [ "mosquitto.service" ];
        before = [ "mosquitto.service" ];
      };
      mosquitto-kick = {
        enable = true;
        description = "Restart Mosquitto after network address is available";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-addresses-br-mqtt.service" ];
        script = ''
          while ! systemctl restart mosquitto.service
          do
            sleep 1
            systemctl stop mosquitto.service || true
          done          
        '';
        serviceConfig = {
          Type = "oneshot";
        };
      };
    };
  };
}
