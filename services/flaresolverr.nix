{ config, ... }:
{
  configStorage = false;
  container = {
    readOnly = false;
    pullImage = import ../images/flaresolverr.nix;
    ports = [
      "8191"
    ];
    environment = {
      TZ = config.time.timeZone;
    };
  };
}
