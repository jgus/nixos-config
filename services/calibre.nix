let
  user = "josh";
  group = "plex";
in
{ config, ... }:
{
  requires = [ "storage-media.mount" ];
  docker = {
    pullImage =
      # nix-shell -p nix-prefetch-docker --run 'nix-prefetch-docker --quiet --image-name lscr.io/linuxserver/calibre-web --image-tag latest'
      {
        imageName = "lscr.io/linuxserver/calibre-web";
        imageDigest = "sha256:f76306b65a5f8c884683652a3586d084c1f16e34ba983c58492aaade52df9b08";
        hash = "sha256-rmMmccf8ehuZ8/X9oABX0vNNmJmoitC6WJNIxxTK+pA=";
        finalImageName = "lscr.io/linuxserver/calibre-web";
        finalImageTag = "latest";
      };
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      TZ = config.time.timeZone;
      DOCKER_MODS = "linuxserver/mods:universal-calibre";
    };
    ports = [ "8083" ];
    configVolume = "/config";
    volumes = [
      "/storage/media:/media"
    ];
  };
}
