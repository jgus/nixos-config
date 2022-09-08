{ pkgs, ... }:

{
  system.activationScripts = {
    docker-setup.text = ''
      ${pkgs.zfs}/bin/zfs list d/varlib/docker >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create d/varlib/docker
    '';
  };

  virtualisation = {
    docker = {
      enable = true;
      enableOnBoot = true;
      autoPrune.enable = true;
      storageDriver = "zfs";
    };
  };
}
