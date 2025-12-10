let
  pw = import ./../.secrets/passwords.nix;
  user = "josh";
  group = "plex";
in
{ config, ... }:
{
  requires = [ "storage-scratch.mount" ];
  docker = {
    image = "lscr.io/linuxserver/transmission";
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      TZ = config.time.timeZone;
      USER = "josh";
      PASS = pw.transmission;
    };
    ports = [
      "9091"
      "51413"
      "51413/udp"
    ];
    configVolume = "/config";
    volumes = [
      "/storage/scratch/torrent:/torrent"
    ];
    # extraOptions = [
    #   "--cap-add=NET_ADMIN"
    # ];
  };
}
