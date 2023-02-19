{ config, pkgs, ... }:

{
  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  nix.settings = {
    cores = 1;
    max-jobs = 1;
  };
}
