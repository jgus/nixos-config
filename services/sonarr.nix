let
  user = "josh";
  group = "plex";
in
{ config, pkgs, ... }:
{
  requires = [ "storage-media.mount" "storage-scratch.mount" ];
  docker = {
    pullImage =
      # nix-shell -p nix-prefetch-docker --run 'nix-prefetch-docker --quiet --image-name lscr.io/linuxserver/sonarr --image-tag latest'
      {
        imageName = "lscr.io/linuxserver/sonarr";
        imageDigest = "sha256:8b9f2138ec50fc9e521960868f79d2ad0d529bc610aef19031ea8ff80b54c5e0";
        hash = "sha256-0WTY5dP+EpqbmjN9MWJv7levplcBvWGr5Kr8mkt/Do8=";
        finalImageName = "lscr.io/linuxserver/sonarr";
        finalImageTag = "latest";
      };
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      TZ = config.time.timeZone;
    };
    ports = [
      "8989"
    ];
    configVolume = "/config";
    volumes = [
      "/storage/scratch/torrent:/torrent"
      "/storage/scratch/usenet:/usenet"
      "/storage/media:/media"
    ];
  };
}
