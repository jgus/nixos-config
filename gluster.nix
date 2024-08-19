{ config, pkgs, lib, ... }:

let
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
  base-port = 49152;
  max-port = 60999;
  bricks = rec {
    deep = [ "b1:/d/gluster" "c1-1:/d/gluster" "d1:/d/gluster" ];
    wide = deep ++ (map (n: "${n}:/gluster") addresses.serverNames);
  };
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
  environment.systemPackages = 
  let
    gluster-varlib-migrate = brickset: pkgs.writeShellScriptBin "gluster-varlib-migrate-${brickset}" ''
      set -e
      NAME=$1
      VOLNAME=varlib-''${NAME}
      MOUNTPOINT=/var/lib/''${NAME}

      gluster volume create ''${VOLNAME} replica ${toString (builtins.length bricks.${brickset})} ${builtins.concatStringsSep " " (map (s: "${s}/\${VOLNAME}") bricks.${brickset})} force
      gluster volume start ''${VOLNAME}
      gluster volume set ''${VOLNAME} cluster.quorum-type none
      zfs set mountpoint=''${MOUNTPOINT}.0 r/varlib/''${NAME}
      mkdir -p ''${MOUNTPOINT}
      mount -t glusterfs localhost:/''${VOLNAME} ''${MOUNTPOINT}
      rsync -arPW ''${MOUNTPOINT}.0/ ''${MOUNTPOINT}/
      zfs set canmount=off r/varlib/''${NAME}
      rm -r ''${MOUNTPOINT}.0
    '';
    gluster-varlib-migrate-deep = gluster-varlib-migrate "deep";
    gluster-varlib-migrate-wide = gluster-varlib-migrate "wide";
  in
  [
    gluster-varlib-migrate-deep
    gluster-varlib-migrate-wide
  ];
}
