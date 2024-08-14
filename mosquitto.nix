{ config, pkgs, ... }:

let
  service = "mosquitto";
  user = "mosquitto";
  group = "mosquitto";
  pw = import ./.secrets/passwords.nix;
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
in
if (machine.hostName != addresses.records."${service}".host) then {} else
{
  networking = {
    macvlans."lan-${service}" = {
      interface = "${machine.lan-interface}";
      mode = "bridge";
    };
    interfaces."lan-${service}" = {
      macAddress = addresses.records.${service}.mac;
      ipv4.addresses = [ { address = addresses.records.${service}.ip; prefixLength = addresses.network.prefixLength; } ];
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
        address = addresses.records.${service}.ip;
        users = {
          ha = {
            acl = [ "readwrite #" ];
            password = pw.mqtt.ha;
          };
          frigate = {
            acl = [ "readwrite #" ];
            password = pw.mqtt.frigate;
          };
          zigbee2mqtt = {
            acl = [ "readwrite #" ];
            password = pw.mqtt.zigbee2mqtt;
          };
          theater_remote = {
            acl = [ "readwrite #" ];
            password = pw.mqtt.theater_remote;
          };
          frodo = {
            acl = [ "readwrite valetudo/Frodo/#" ];
            password = pw.mqtt.frodo;
          };
          sam = {
            acl = [ "readwrite valetudo/Sam/#" ];
            password = pw.mqtt.sam;
          };
          merry = {
            acl = [ "readwrite valetudo/Merry/#" ];
            password = pw.mqtt.merry;
          };
          pippin = {
            acl = [ "readwrite valetudo/Pippin/#" ];
            password = pw.mqtt.pippin;
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
    };
  };
}
