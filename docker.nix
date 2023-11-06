{ config, pkgs, lib, ... }:

{
  
  system.activationScripts = lib.mkIf (lib.elem pkgs.zfs config.environment.systemPackages) {
    docker-setup.text = ''
      ${pkgs.zfs}/bin/zfs list r/varlib/docker >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create r/varlib/docker
    '';
  };

  virtualisation = {
    docker = {
      enable = true;
      enableOnBoot = true;
      autoPrune.enable = true;
      storageDriver = if (lib.elem pkgs.zfs config.environment.systemPackages) then "zfs" else null;
      daemon.settings = {
        dns = ["172.22.0.1"];
      };
    };
  };
}
