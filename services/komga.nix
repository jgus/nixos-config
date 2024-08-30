let
  user = "josh";
  group = "plex";
in
{ config, ... }:
{
  inherit user group;
  requires = [ "storage-media.mount" ];
  docker = {
    image = "gotson/komga";
    environment = {
      TZ = config.time.timeZone;
      SERVER_PORT = "25600";
    };
    ports = [
      "25600"
    ];
    configVolume = "/config";
    volumes = [
      "/storage/media/Comics:/data"
    ];
  };
}
