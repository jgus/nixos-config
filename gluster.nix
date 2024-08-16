{ config, pkgs, lib, ... }:

let
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
  base-port = 49152;
  max-port = 60999;
in
{
  networking.firewall = {
    allowedTCPPorts = [ 24007 24008 ];
    allowedTCPPortRanges = [ { from = base-port; to = max-port; } ];
    allowedUDPPorts = [ 24007 24008 ];
    allowedUDPPortRanges = [ { from = base-port; to = max-port; } ];
  };
  services = {
    glusterfs.enable = true;
  };
  # system.activationScripts = {
  #     gluster-peers.text = ''
  #       for i in ''${SERVER_NAMES}
  #       do
  #         ${pkgs.glusterfs}/bin/gluster peer probe ''${i} >/dev/null
  #       done
  #     '';
  #     gluster-bricks.text =
  #     if machine.zfs then
  #     ''
  #       for p in r ${builtins.concatStringsSep " " machine.zfs-pools}
  #       do
  #         ${pkgs.zfs}/bin/zfs list ''${p}/gluster >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create ''${p}/gluster
  #       done
  #     ''
  #     else
  #     ''
  #       [ -d /gluster ] || mkdir /gluster
  #     '';
  #   };

  fileSystems."/home.new" = {
    device = "localhost:/home";
    fsType = "glusterfs";
  };
}
