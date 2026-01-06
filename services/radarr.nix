let
  user = "josh";
  group = "media";
in
{ config, ... }:
{
  requires = [ "storage-media.mount" "storage-scratch.mount" ];
  container = {
    readOnly = false;
    pullImage = import ../images/radarr.nix;
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
