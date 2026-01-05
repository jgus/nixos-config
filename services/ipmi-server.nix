{ config, ... }:
{
  configStorage = false;
  container = {
    readOnly = false;
    pullImage = import ../images/ipmi-server.nix;
    environment = {
      TZ = config.time.timeZone;
    };
    ports = [
      "80"
    ];
  };
}
