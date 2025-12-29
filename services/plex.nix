let
  user = "plex";
  group = "plex";
in
{ config, ... }:
{
  requires = [ "storage-media.mount" "storage-photos.mount" ];
  container = {
    pullImage = {
      imageName = "lscr.io/linuxserver/plex";
      imageDigest = "sha256:1720efa8e919a724ff3003cce7c1c0ae91a54e097ca3c8f6713a780c6fd73432";
      hash = "sha256-rwEr4bCiOkmjjV6AdZzofxBceWOOrL5yg+bleAsQGHo=";
      finalImageName = "lscr.io/linuxserver/plex";
      finalImageTag = "latest";
    };
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
      "--tmpfs=/tmp"
    ];
  };
}
