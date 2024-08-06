{ pkgs, ... }:

{
  systemd = {
    services = {
      offsite-josh-ws = {
        path = with pkgs; [
          openssh
          zfs
          zfs-autobackup
        ];
        script = ''
          zfs list d/offsite/josh-ws >/dev/null || zfs create d/offsite/josh-ws
          zfs-autobackup --verbose --ssh-source root@josh-ws --keep-source 10,1d2w,1w2m,1m1y --keep-target 10,1d2w,1w2m,1m1y --decrypt --encrypt --filter-properties mountpoint offsite-josh-ws d/offsite/josh-ws
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        startAt = "daily";
      };
    };
  };
}
