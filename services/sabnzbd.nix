let
  user = "josh";
  group = "media";
in
{ config, ... }:
{
  requires = [ "storage-scratch.mount" ];
  container = {
    readOnly = false;
    pullImage = import ../images/sabnzbd.nix;
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      TZ = config.time.timeZone;
    };
    ports = [
      "8080"
    ];
    configVolume = "/config";
    volumes = [
      "/storage/scratch/usenet:/config/Downloads"
    ];
  };
}
