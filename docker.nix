{ config, pkgs, lib, ... }:

let
  machine = import ./machine.nix;
in
{
  system.activationScripts = {
    docker-setup-dhcp.text = ''
      ${pkgs.docker}/bin/docker plugin ls --format "{{.Name}}" | grep "^net-dhcp:latest$" || ${pkgs.docker}/bin/docker plugin install --grant-all-permissions --alias net-dhcp ghcr.io/devplayer0/docker-net-dhcp:release-linux-amd64
      ${pkgs.docker}/bin/docker network ls --format "{{.Name}}" | grep "^dhcp-net$" || ${pkgs.docker}/bin/docker network create -d net-dhcp:latest --ipam-driver null -o bridge=br0 dhcp-net
    '';
    docker-setup-zfs.text = if machine.zfs then ''
      ${pkgs.zfs}/bin/zfs list r/varlib/docker >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create r/varlib/docker
    '' else "";
  };

  virtualisation = {
    docker = {
      enable = true;
      enableOnBoot = true;
      autoPrune.enable = true;
      storageDriver = if machine.zfs then "zfs" else null;
      daemon.settings = {
        dns = [ "172.22.0.1" ];
      };
    };
    oci-containers = {
      backend = "docker";
      containers = {};
    };
  };
}
