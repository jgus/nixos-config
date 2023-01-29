{ pkgs, ... }:

{
  systemd = {
    services = {
      sync-to-cloud = {
        enable = true;
        path = with pkgs; [
          bash
          gawk
          hostname
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
