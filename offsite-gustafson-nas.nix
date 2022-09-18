{ pkgs, ... }:

{
  systemd = {
    services = {
      offsite-gustafson-nas = {
        path = with pkgs; [
          openssh
          zfs
          zfs-autobackup
        ];
        script = ''
          zfs-autobackup --verbose --ssh-source gustafson-backup-reverse --decrypt --encrypt --filter-properties mountpoint offsite-gustafson-nas d/offsite/gustafson-nas
        '';
        serviceConfig = {
          Type = "oneshot";
        };
      };
    };
    timers = {
      offsite-gustafson-nas = {
        enable = true;
        wantedBy = [ "timers.target" ];
        partOf = [ "offsite-gustafson-nas.service" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
          Unit = "offsite-gustafson-nas.service";
        };
      };
    };
  };

  system.activationScripts = {
    offsite-jarvis.text = ''
      ${pkgs.zfs}/bin/zfs list d/offsite/gustafson-nas >/dev/null || ${pkgs.zfs}/bin/zfs create d/offsite/gustafson-nas -o readonly=on
    '';
  };
}
