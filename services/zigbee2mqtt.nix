{ config, ... }:
{
  docker = {
    image = "koenkk/zigbee2mqtt";
    configVolume = "/app/data";
    environment = {
      TZ = config.time.timeZone;
    };
    ports = [
      "8081"
    ];
  };
}
