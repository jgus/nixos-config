let
  addresses = import ./../addresses.nix;
  user = "plex";
  group = "plex";
in
{ config, ... }:
let
  uid = toString config.users.users.${user}.uid;
  gid = toString config.users.groups.${group}.gid;
in
{
  requires = [ "storage-media.mount" "storage-photos.mount" ];
  docker = {
    image = "lscr.io/linuxserver/jellyfin";
    environment = {
      PUID = uid;
      PGID = gid;
      TZ = config.time.timeZone;
      JELLYFIN_PublishedServerUrl = "all=https://jellyfin.gustafson.me";
    };
    configVolume = "/config";
    volumes = [
      "/storage/media:/media"
      "/storage/photos:/photos"
    ];
    extraOptions = [
      "--device=nvidia.com/gpu=0"
      "--device=/dev/dri:/dev/dri"
      "--tmpfs=/tmp:exec,uid=${uid},gid=${gid}"
      "--tmpfs=/config/cache/transcodes:exec,uid=${uid},gid=${gid}"
    ];
  };
}
