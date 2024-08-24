{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  user = "josh";
  group = "plex";
in
{
  imports = [(homelabService {
    name = "lidarr";
    requires = [ "nas.mount" ];
    docker = {
      image = "lscr.io/linuxserver/lidarr";
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
        "/nas/scratch/peer:/peer"
        "/nas/scratch/usenet:/usenet"
        "/nas/media:/media"
      ];
    };
  })];
}
