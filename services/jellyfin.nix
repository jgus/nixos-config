let
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
  container = {
    readOnly = false;
    pullImage = import ../images/jellyfin.nix;
    environment = {
      PUID = uid;
      PGID = gid;
      TZ = config.time.timeZone;
      JELLYFIN_PublishedServerUrl = "http://jellyfin.home.gustafson.me:8096";
      # NVIDIA_VISIBLE_DEVICES = "GPU-35f1dd5f-a7af-1980-58e4-61bec60811dd";
    };
    configVolume = "/config";
    volumes = [
      "/storage/media:/media"
      "/storage/photos:/photos"
    ];
    extraOptions = [
      "--device=nvidia.com/gpu=GPU-35f1dd5f-a7af-1980-58e4-61bec60811dd"
      "--device=/dev/dri:/dev/dri"
      "--tmpfs=/tmp:exec,mode=1777"
      "--tmpfs=/config/cache/transcodes:exec,mode=1777"
    ];
  };
}
