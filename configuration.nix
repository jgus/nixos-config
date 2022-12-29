{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix

      ./interfaces.nix

      ./common.nix
      ./host.nix
      ./users.nix

      ./nvidia.nix
      ./vscode.nix
      ./zfs.nix
      ./clamav.nix

      #./pihole.nix
      ./ddclient.nix
      ./wireguard.nix
      ./landing.nix
      ./samba.nix
      ./syncthing.nix
      ./transmission.nix
      ./www.nix
      ./ntp.nix
      ./plex.nix
      ./minecraft.nix

      ./libvirt.nix
      ./vm-vm1.nix

      ./offsite-sm1.nix
    ];
}
