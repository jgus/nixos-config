{ config, ... }:
{
  configStorage = false;
  container = {
    pullImage = import ../images/ipmi-server.nix;
    environment = {
      TZ = config.time.timeZone;
    };
    ports = [
      "80"
    ];
  };
}
