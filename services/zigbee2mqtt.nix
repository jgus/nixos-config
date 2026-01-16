{ config, ... }:
{
  container = {
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
