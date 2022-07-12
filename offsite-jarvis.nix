{ pkgs, ... }:

{
  systemd = {
    services = {
      offsite-jarvis = {
        path = with pkgs; [
          openssh
          zfs
          zfs-autobackup
        ];
        script = ''
          zfs-autobackup --verbose --ssh-source root@jarvis --keep-source 10,1d2w,1w2m,1m1y --keep-target 10,1d2w,1w2m,1m1y --filter-properties mountpoint offsite-jarvis d/offsite/jarvis
        '';
        serviceConfig = {
          Type = "oneshot";
        };
      };
    };
    timers = {
      offsite-jarvis = {
        enable = true;
        wantedBy = [ "timers.target" ];
        partOf = [ "offsite-jarvis.service" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
          Unit = "offsite-jarvis.service";
        };
      };
    };
  };

  system.activationScripts = {
    offsite-jarvis.text = ''
      ${pkgs.zfs}/bin/zfs list d/offsite/jarvis >/dev/null || ${pkgs.zfs}/bin/zfs create d/offsite/jarvis -o readonly=on
    '';
  };
}
