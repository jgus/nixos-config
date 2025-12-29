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
    pullImage = {
      imageName = "lscr.io/linuxserver/jellyfin";
      imageDigest = "sha256:ed5dc797d12089271e0e61a740cbf9626c4e513400ca2d96c54d35500eeb907c";
      hash = "sha256-V/kbgPySsQfCsQ1YK5UmpgykT72mER1aJSKJpGyOlPU=";
      finalImageName = "lscr.io/linuxserver/jellyfin";
      finalImageTag = "latest";
    };
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
      "--tmpfs=/tmp:exec,uid=${uid},gid=${gid}"
      "--tmpfs=/config/cache/transcodes:exec,uid=${uid},gid=${gid}"
    ];
  };
}
