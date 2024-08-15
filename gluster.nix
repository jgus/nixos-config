{ config, pkgs, lib, ... }:

let
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
  base-port = 49152;
  max-port = 49200;
in
{
  environment.etc = {
    "glusterfs/glusterd.vol".text = ''
      volume management
        type mgmt/glusterd
        option base-port ${toString base-port}
        option max-port ${toString max-port}
      end-volume
    '';
  };
  networking.firewall = {
    allowedTCPPorts = [ 24007 24008 ] ++ (lib.lists.range base-port max-port);
    allowedUDPPorts = [ 24007 24008 ] ++ (lib.lists.range base-port max-port);
  };
  services = {
    glusterfs.enable = true;
  };
}
