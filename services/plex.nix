let
  user = "media";
  group = "media";
in
{ config, ... }:
{
  requires = [ "storage-media.mount" "storage-photos.mount" ];
  container = {
    readOnly = false;
    pullImage = import ../images/plex.nix;
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      TZ = config.time.timeZone;
      VERSION = "latest";
      # NVIDIA_VISIBLE_DEVICES = "GPU-35f1dd5f-a7af-1980-58e4-61bec60811dd";
    };
    configVolume = "/config";
    volumes = [
      "/storage/media:/media"
      "/storage/photos:/shares/photos"
    ];
    extraOptions = [
      "--device=nvidia.com/gpu=GPU-35f1dd5f-a7af-1980-58e4-61bec60811dd"
      "--device=/dev/dri:/dev/dri"
    ];
    tmpFs = [
      "/tmp"
    ];
  };
}
