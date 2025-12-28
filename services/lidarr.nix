let
  user = "josh";
  group = "plex";
in
{ config, pkgs, ... }:
{
  requires = [ "storage-media.mount" "storage-scratch.mount" ];
  docker = {
    pullImage =
      # nix-shell -p nix-prefetch-docker --run 'nix-prefetch-docker --quiet --image-name lscr.io/linuxserver/lidarr --image-tag latest'
      {
        imageName = "lscr.io/linuxserver/lidarr";
        imageDigest = "sha256:ede2bb17350cc97a0d3f24389aa91803f655eac29aa022c77a71f4a61cc621e4";
        hash = "sha256-Gsd3/lroAe8qx0WZVwVYWbjK2bGMLX8096tE242V3J0=";
        finalImageName = "lscr.io/linuxserver/lidarr";
        finalImageTag = "latest";
      };
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      TZ = config.time.timeZone;
    };
    ports = [
      "8686"
    ];
    configVolume = "/config";
    volumes = [
      "/storage/scratch/torrent:/torrent"
      "/storage/scratch/usenet:/usenet"
      "/storage/media:/media"
    ];
  };
}
