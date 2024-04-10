{ config, pkgs, ... }:

let pw = import ./.secrets/passwords.nix;
in
{
  system.activationScripts = {
    mqttSetup.text = ''
      ${pkgs.zfs}/bin/zfs list r/varlib/mosquitto >/dev/null 2>&1 || ( ${pkgs.zfs}/bin/zfs create r/varlib/mosquitto && chown mosquitto:mosquitto /var/lib/mosquitto )
    '';
  };

  networking.firewall.allowedTCPPorts = [ 1883 ];

  services.mosquitto = {
    enable = true;
    dataDir = "/var/lib/mosquitto";
    # logType = [ "all" ];
    listeners = [
      {
        users.ha = {
          acl = [ "readwrite #" ];
          password = "${pw.mqtt.ha}";
        };
        users.frigate = {
          acl = [ "readwrite #" ];
          password = "${pw.mqtt.frigate}";
        };
        users.frodo = {
          acl = [ "readwrite valetudo/Frodo/#" ];
          password = "${pw.mqtt.frodo}";
        };
        users.sam = {
          acl = [ "readwrite valetudo/Sam/#" ];
          password = "${pw.mqtt.sam}";
        };
        users.merry = {
          acl = [ "readwrite valetudo/Merry/#" ];
          password = "${pw.mqtt.merry}";
        };
        users.pippin = {
          acl = [ "readwrite valetudo/Pippin/#" ];
          password = "${pw.mqtt.pippin}";
        };
      }
    ];
  };
}
