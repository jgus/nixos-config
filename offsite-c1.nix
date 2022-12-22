{ pkgs, ... }:

{
  systemd = {
    services = {
      offsite-c1 = {
        path = with pkgs; [
          openssh
          zfs
          zfs-autobackup
        ];
        script = ''
          zfs-autobackup --verbose --ssh-source root@c1 --keep-source 10,1d2w,1w2m,1m1y --keep-target 10,1d2w,1w2m,1m1y --decrypt --encrypt --filter-properties mountpoint offsite-c1 d/offsite/c1
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        startAt = "daily";
      };
    };
  };

  system.activationScripts = {
    offsite-c1.text = ''
      ${pkgs.zfs}/bin/zfs list d/offsite/c1 >/dev/null || ${pkgs.zfs}/bin/zfs create d/offsite/c1 -o readonly=on
    '';
  };
}
