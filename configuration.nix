{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      ./interfaces.nix

      ./common.nix
      ./host.nix
      ./users.nix

      #./docker.nix
      #./plex.nix
      ./samba.nix
      ./vscode.nix
      ./zfs.nix
    ];
}
