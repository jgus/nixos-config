let
  user = "media";
  group = "media";
in
{ config, ... }:
{
  homelab.services.plex = {
    requires = [ "storage-media.mount" "storage-photos.mount" ];
    container = {
      pullImage = import ../../images/plex.nix;
      readOnly = false;
      devices = [
        "nvidia.com/gpu=GPU-35f1dd5f-a7af-1980-58e4-61bec60811dd"
        "/dev/dri:/dev/dri"
      ];
      environment = {
        PUID = toString config.users.users.${user}.uid;
        PGID = toString config.users.groups.${group}.gid;
        VERSION = "latest";
        # NVIDIA_VISIBLE_DEVICES = "GPU-35f1dd5f-a7af-1980-58e4-61bec60811dd";
      };
      configVolume = "/config";
      volumes = [
        "/storage/media:/media"
        "/storage/photos:/shares/photos"
      ];
      tmpFs = [
        "/tmp"
      ];
    };
  };
}
