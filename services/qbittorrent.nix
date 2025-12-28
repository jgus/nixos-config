let
  user = "josh";
  group = "plex";
in
{ config, pkgs, ... }:
{
  requires = [ "storage-scratch.mount" ];
  docker = {
    image = "lscr.io/linuxserver/qbittorrent";
    imageFile = pkgs.dockerTools.pullImage
      # nix-shell -p nix-prefetch-docker --run 'nix-prefetch-docker --quiet --image-name lscr.io/linuxserver/qbittorrent --image-tag latest'
      {
        imageName = "lscr.io/linuxserver/qbittorrent";
        imageDigest = "sha256:a68c4cfb7b07c39cf3f13e7f1d23d333c1e4a60304d37bc1eec7af3eacfe12d5";
        hash = "sha256-Mwmpc5drI0GV3DYqog5/COd4f6zizEc4KaqRevLmSxk=";
        finalImageName = "lscr.io/linuxserver/qbittorrent";
        finalImageTag = "latest";
      };
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      TZ = config.time.timeZone;
      WEBUI_PORT = "80";
      TORRENTING_PORT = "6881";
    };
    ports = [
      "80"
      "6881"
      "6881/udp"
    ];
    configVolume = "/config";
    volumes = [
      "/storage/scratch/torrent:/torrent"
    ];
  };
}
