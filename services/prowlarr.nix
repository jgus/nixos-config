{ config, ... }:
let
  user = "josh";
  group = "plex";
in
{
  docker = {
    image = "lscr.io/linuxserver/prowlarr";
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      TZ = config.time.timeZone;
    };
    ports = [
      "9696"
    ];
    configVolume = "/config";
  };
}
