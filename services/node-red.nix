{ config, ... }:
{
  container = {
    readOnly = false;
    pullImage = import ../images/node-red.nix;
    configVolume = "/data";
    environment = {
      TZ = config.time.timeZone;
    };
    ports = [
      "1880"
    ];
  };
}
