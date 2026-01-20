let
  user = "media";
  group = "media";
in
{ addresses, config, ... }:
{
  requires = [ "storage-media.mount" "storage-photos.mount" ];
  container = {
    readOnly = false;
    pullImage = import ../images/jellyfin.nix;
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      JELLYFIN_PublishedServerUrl = "http://jellyfin.${addresses.network.domain}:8096";
      # NVIDIA_VISIBLE_DEVICES = "GPU-35f1dd5f-a7af-1980-58e4-61bec60811dd";
    };
    configVolume = "/config";
    volumes = [
      "/storage/media:/media"
      "/storage/photos:/photos"
    ];
    devices = [
      "nvidia.com/gpu=GPU-35f1dd5f-a7af-1980-58e4-61bec60811dd"
      "/dev/dri:/dev/dri"
    ];
    tmpFs = [
      "/tmp"
      "/config/cache/transcodes:exec,mode=0777"
    ];
  };
}
