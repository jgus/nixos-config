{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  user = "josh";
  group = "plex";
in
{
  imports = [(homelabService {
    name = "mylar";
    requires = [ "nas.mount" ];
    docker = {
      image = "lscr.io/linuxserver/mylar3";
      environment = {
        PUID = toString config.users.users.${user}.uid;
        PGID = toString config.users.groups.${group}.gid;
        TZ = config.time.timeZone;
      };
      ports = [
        "8090"
      ];
      configVolume = "/config";
      volumes = [
        "/nas/media/Comics:/comics"
        "/nas/media/Comics.import:/import"
        "/nas/scratch/peer:/peer"
        "/nas/scratch/usenet:/usenet"
      ];
      extraOptions = [
        "--tmpfs=/config/mylar/cache"
      ];
    };
  })];
}
