{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      ./interfaces.nix

      ./common.nix
      ./x86.nix
      ./host.nix
      ./users.nix
      ./nas.nix

      #./nvidia.nix
      ./vscode.nix
      ./zfs.nix
      ./clamav.nix # needs .secrets/gmail-password.nix

      ./samba.nix
      ./docker.nix

      #./syncthing.nix

      ./libvirt.nix
      ./vm-josh-pc.nix
    ];
}
