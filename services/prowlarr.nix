let
  user = "josh";
  group = "plex";
in
{ config, ... }:
{
  container = {
    readOnly = false;
    pullImage = import ../images/prowlarr.nix;
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
