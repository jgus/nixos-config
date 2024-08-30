let
  user = "josh";
  group = "plex";
in
{ config, pkgs, ... }:
{
  requires = [ "storage-scratch.mount" ];
  docker = {
    image = "lscr.io/linuxserver/sabnzbd";
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      TZ = config.time.timeZone;
    };
    ports = [
      "8080"
    ];
    configVolume = "/config";
    volumes = [
      "/storage/scratch/usenet:/config/Downloads"
    ];
  };
}
