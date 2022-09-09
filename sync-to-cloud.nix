{ pkgs, ... }:

{
  systemd = {
    services = {
      sync-to-cloud = {
        path = with pkgs; [
          bash
          gawk
          rclone
          zfs
        ];
        script = ''
          /etc/nixos/bin/sync-to-cloud.sh
        '';
        serviceConfig = {
          Type = "oneshot";
        };
      };
    };
    timers = {
      sync-to-cloud = {
        enable = true;
        wantedBy = [ "timers.target" ];
        partOf = [ "sync-to-cloud.service" ];
        timerConfig = {
          OnCalendar = "Sun 4:00";
          Persistent = true;
          Unit = "sync-to-cloud.service";
        };
      };
    };
  };
}
