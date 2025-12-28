let
  user = "josh";
  group = "plex";
in
{ config, ... }:
{
  requires = [ "storage-media.mount" ];
  docker = {
    pullImage =
      # nix-shell -p nix-prefetch-docker --run 'nix-prefetch-docker --quiet --image-name lscr.io/linuxserver/lazylibrarian --image-tag latest'
      {
        imageName = "lscr.io/linuxserver/lazylibrarian";
        imageDigest = "sha256:218ef302d43de82c219d096c651ca7461d224537674a08d0489ea087cdcd8ad2";
        hash = "sha256-w5hTxhwDZqpNWSOR06IJLjUJS7M2kU7F/yWMO1B/XTo=";
        finalImageName = "lscr.io/linuxserver/lazylibrarian";
        finalImageTag = "latest";
      };
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      TZ = config.time.timeZone;
      DOCKER_MODS = "linuxserver/mods:universal-calibre|linuxserver/mods:lazylibrarian-ffmpeg";
    };
    ports = [ "5299" ];
    configVolume = "/config";
    volumes = [
      "/storage/scratch/torrent:/torrent"
      "/storage/scratch/usenet:/usenet"
      "/storage/media:/media"
    ];
  };
}
