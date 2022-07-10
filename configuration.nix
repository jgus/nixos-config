{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      ./interfaces.nix

      ./common.nix
      ./host.nix
      ./users.nix

      ./plex.nix
      ./vscode.nix
      ./zfs.nix
      ./clamav.nix
    ];
}
