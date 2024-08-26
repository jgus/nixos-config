{ config, pkgs, ... }:

with builtins;
{
  imports = [ ./msmtp.nix ];

  services = {
    clamav = {
      daemon.enable = false; # use clamscan instead of clamdscan
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
          [ -d /var/lib/clamav ] || freshclam
          clamscan -r --cross-fs=no -i --move=/boot/INFECTED /boot/
          EXCLUDE_FILES=(
          )
          EXCLUDE_DIRS=(
            /nix/store/yzcyxsfc207vrwfysdldmjkswfhv7swg-source/tests/oss-fuzz/pe_fuzzer_corpus
          )
          ${readFile ./clamav/clamav-scan-zfs.sh}
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        startAt = "daily";
      };
    };
  };
}
