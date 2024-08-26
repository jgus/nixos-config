{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  user = "josh";
  group = "plex";
in
{
  imports = [(homelabService {
    name = "radarr";
    requires = [ "storage-media.mount" "storage-scratch.mount" ];
    docker = {
      image = "lscr.io/linuxserver/radarr";
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
        "/storage/scratch/peer:/peer"
        "/storage/scratch/usenet:/usenet"
        "/storage/media:/media"
      ];
    };
  })];
}
