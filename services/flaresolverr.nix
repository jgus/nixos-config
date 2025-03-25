{ config, ... }:
{
  configStorage = false;
  docker = {
    image = "ghcr.io/flaresolverr/flaresolverr:latest";
    ports = [
      "8191"
    ];
    environment = {
      TZ = config.time.timeZone;
    };
  };
}
