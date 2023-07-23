{ pkgs, ... }:

{
  # pin docker to older nixpkgs: https://github.com/NixOS/nixpkgs/issues/244159
  nixpkgs.overlays = [
    (let
      pinnedPkgs = import(pkgs.fetchFromGitHub {
        owner = "NixOS";
        repo = "nixpkgs";
        rev = "b6bbc53029a31f788ffed9ea2d459f0bb0f0fbfc";
        sha256 = "sha256-JVFoTY3rs1uDHbh0llRb1BcTNx26fGSLSiPmjojT+KY=";
      }) {};
    in
    final: prev: {
      docker = pinnedPkgs.docker;
    })
  ];
  
  system.activationScripts = {
    docker-setup.text = ''
      ${pkgs.zfs}/bin/zfs list r/varlib/docker >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create r/varlib/docker
    '';
  };

  virtualisation = {
    docker = {
      enable = true;
      enableOnBoot = true;
      autoPrune.enable = true;
      storageDriver = "zfs";
      daemon.settings = {
        dns = ["172.22.0.1"];
      };
    };
  };
}
