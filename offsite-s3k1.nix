{ pkgs, ... }:

{
  systemd = {
    services = {
      offsite-s3k1 = {
        path = with pkgs; [
          openssh
          zfs
          zfs-autobackup
        ];
        script = ''
          zfs-autobackup --verbose --ssh-source root@s3k1 --keep-source 10,1d2w,1w2m,1m1y --keep-target 10,1d2w,1w2m,1m1y --decrypt --encrypt --filter-properties mountpoint offsite-s3k1 d/offsite/s3k1
        '';
        serviceConfig = {
          Type = "oneshot";
        };
      };
    };
    timers = {
      offsite-s3k1 = {
        enable = true;
        wantedBy = [ "timers.target" ];
        partOf = [ "offsite-s3k1.service" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
          Unit = "offsite-s3k1.service";
        };
      };
    };
  };

  system.activationScripts = {
    offsite-s3k1.text = ''
      ${pkgs.zfs}/bin/zfs list d/offsite/s3k1 >/dev/null || ${pkgs.zfs}/bin/zfs create d/offsite/s3k1 -o readonly=on
    '';
  };
}
