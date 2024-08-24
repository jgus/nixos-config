{ config, pkgs, ... }:

with (import ./functions.nix) { inherit pkgs; };
{
  imports = [(homelabService {
    name = "ntp";
    configStorage = false;
    docker = {
      image = "ntp";
      ports = [
        "123/udp"
      ];
      extraOptions = [
        "--read-only"
        "--tmpfs=/etc/chrony:rw,mode=1750"
        "--tmpfs=/run/chrony:rw,mode=1750"
        "--tmpfs=/var/lib/chrony:rw,mode=1750"
      ];
    };
  })];
}
