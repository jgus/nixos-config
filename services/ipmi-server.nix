{ config, ... }:
{
  configStorage = false;
  docker = {
    image = "mneveroff/ipmi-server";
    environment = {
      TZ = config.time.timeZone;
    };
    ports = [
      "80"
    ];
  };
}
