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
    listeners = [
      {
        users.ha = {
          acl = [
            "readwrite #"
          ];
          password = "${pw.mqtt.ha}";
        };
        users.frigate = {
          acl = [
            "readwrite #"
          ];
          password = "${pw.mqtt.frigate}";
        };
      }
    ];
  };
}
