let
  user = "josh";
  group = "plex";
in
{ config, ... }:
{
  requires = [ "storage-media.mount" "storage-scratch.mount" ];
  docker = {
    pullImage =
      # nix-shell -p nix-prefetch-docker --run 'nix-prefetch-docker --quiet --image-name lscr.io/linuxserver/radarr --image-tag latest'
      {
        imageName = "lscr.io/linuxserver/radarr";
        imageDigest = "sha256:6c0948b42c149e36bb3dbc0b64d36c77b2d3c9dccf1b424c4f72af1e57ba0c21";
        hash = "sha256-HKzZmwlnC0sFjn48f5hTLX3Hi5bCwaFMBk7Y8vQI9jk=";
        finalImageName = "lscr.io/linuxserver/radarr";
        finalImageTag = "latest";
      };
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      TZ = config.time.timeZone;
    };
    ports = [
      "7878"
    ];
    configVolume = "/config";
    volumes = [
      "/storage/scratch/torrent:/torrent"
      "/storage/scratch/usenet:/usenet"
      "/storage/media:/media"
    ];
  };
}
