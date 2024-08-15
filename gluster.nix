{ config, pkgs, ... }:

let
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
in
{
  networking.firewall = {
    allowedTCPPorts = [ 24007 24008 ];
    allowedUDPPorts = [ 24007 24008 ];
  };
  services = {
    glusterfs.enable = true;
  };
}
