{ config, ... }:
{
  configStorage = false;
  container = {
    pullImage = import ../images/flaresolverr.nix;
    ports = [
      "8191"
    ];
    environment = {
      TZ = config.time.timeZone;
    };
  };
}
