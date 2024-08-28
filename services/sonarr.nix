{ config, ... }:
let
  user = "josh";
  group = "plex";
in
{
  requires = [ "storage-media.mount" "storage-scratch.mount" ];
  docker = {
    image = "lscr.io/linuxserver/sonarr";
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      TZ = config.time.timeZone;
    };
    ports = [
      "8989"
    ];
    configVolume = "/config";
    volumes = [
      "/storage/scratch/peer:/peer"
      "/storage/scratch/usenet:/usenet"
      "/storage/media:/media"
    ];
  };
}
