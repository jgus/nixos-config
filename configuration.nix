{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      ./interfaces.nix

      ./common.nix
      ./rpi.nix
      ./host.nix
      ./users.nix

      ./vscode.nix
      #./clamav.nix # needs .secrets/gmail-password.nix

      ./zwave-js-ui.nix
    ];
}
