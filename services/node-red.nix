{ config, ... }:
{
  docker = {
    image = "nodered/node-red";
    configVolume = "/data";
    environment = {
      TZ = config.time.timeZone;
    };
    ports = [
      "1880"
    ];
  };
}
