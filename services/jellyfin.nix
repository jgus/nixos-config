let
  user = "plex";
  group = "plex";
in
{ config, ... }:
{
  requires = [ "storage-media.mount" "storage-photos.mount" ];
  docker = {
    image = "lscr.io/linuxserver/jellyfin";
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      TZ = config.time.timeZone;
      VERSION = "latest";
    };
    configVolume = "/config";
    volumes = [
      "/storage/media:/media"
      "/storage/photos:/photos"
    ];
    extraOptions = [
      "--device=nvidia.com/gpu=0"
      "--device=/dev/dri:/dev/dri"
      "--tmpfs=/tmp"
      "--tmpfs=/config/cache/transcodes"
    ];
  };
}
