{ config, ... }:
{
  container = {
    readOnly = false;
    pullImage = import ../images/zigbee2mqtt.nix;
    configVolume = "/app/data";
    environment = {
      TZ = config.time.timeZone;
    };
    ports = [
      "8081"
    ];
  };
}
