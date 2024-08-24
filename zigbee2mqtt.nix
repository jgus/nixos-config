{ config, pkgs, lib, ... }:

with (import ./functions.nix) { inherit pkgs; };
{
  imports = [(homelabService {
    name = "zigbee2mqtt";
    docker = {
      image = "koenkk/zigbee2mqtt";
      configVolume = "/app/data";
      environment = {
        TZ = config.time.timeZone;
      };
      ports = [
        "8081"
      ];
    };
  })];
}
