{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
let
  user = "josh";
  group = "plex";
in
{
  imports = [(homelabService {
    name = "komga";
    inherit user group;
    requires = [ "storage-media.mount" ];
    docker = {
      image = "gotson/komga";
      environment = {
        TZ = config.time.timeZone;
        SERVER_PORT = "25600";
      };
      ports = [
        "25600"
      ];
      configVolume = "/config";
      volumes = [
        "/storage/media/Comics:/data"
      ];
    };
  })];
}
