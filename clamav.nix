{ config, pkgs, ... }:

{
  imports = [ ./msmtp.nix ];

  environment.etc = {
    "clamav/clamav-scan-zfs.sh".source = ./clamav/clamav-scan-zfs.sh;
  };

  services = {
    clamav = {
      daemon.enable = flase; # use clamscan instead of clamdscan
      updater.enable = true;
    };
  };

  systemd = {
    services = {
      clamav-scan-all = {
        path = with pkgs; [
          bash
          clamav
          hostname
          mount
          msmtp
          sharutils
          umount
          zfs
        ];
        script = ''
          clamscan -r --cross-fs=no -i --move=/boot/INFECTED /boot/
          /etc/clamav/clamav-scan-zfs.sh
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        startAt = "daily";
      };
    };
  };

  system.activationScripts = {
    freshclam.text = ''
      [ -d /var/lib/clamav ] || ${pkgs.clamav}/bin/freshclam
    '';
  };
}
