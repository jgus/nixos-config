{ config, pkgs, lib, ... }:

let
  machine = import ./machine.nix;
  iface = if (machine.arch == "rpi") then "end0" else "br0";
in
{
  system.activationScripts = {
    docker-setup-macvlan.text = ''
      ${pkgs.docker}/bin/docker network ls --format "{{.Name}}" | grep "^macvlan$" || ${pkgs.docker}/bin/docker network create -d macvlan --subnet=172.22.0.0/16 --gateway=172.22.0.1 -o parent=${iface} macvlan
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
