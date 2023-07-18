{ pkgs, ... }:

{
  # Workaround for Docker break https://github.com/NixOS/nixpkgs/issues/244159
  nix.nixPath = [
    "nixpkgs=https://github.com/NixOS/nixpkgs/archive/b6bbc53029a31f788ffed9ea2d459f0bb0f0fbfc.tar.gz"
    "nixos-config=/etc/nixos/configuration.nix"
    "/nix/var/nix/profiles/per-user/root/channels"
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
