let
  user = "josh";
  group = "plex";
in
{ config, pkgs, ... }:
{
  requires = [ "storage-scratch.mount" ];
  docker = {
    image = "lscr.io/linuxserver/transmission";
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      TZ = config.time.timeZone;
    };
    ports = [
      "9091"
      "51413"
    ];
    configVolume = "/config";
    volumes = [
      "/storage/scratch/peer:/peer"
    ];
    extraOptions = [
      "--cap-add=NET_ADMIN"
    ];
  };
}
