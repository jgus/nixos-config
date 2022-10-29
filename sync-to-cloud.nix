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
        startAt = "Sun 4:00";
      };
    };
  };
}
