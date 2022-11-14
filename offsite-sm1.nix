{ pkgs, ... }:

{
  systemd = {
    services = {
      offsite-sm1 = {
        path = with pkgs; [
          openssh
          zfs
          zfs-autobackup
        ];
        script = ''
          zfs-autobackup --verbose --ssh-source root@sm1 --keep-source 10,1d2w,1w2m,1m1y --keep-target 10,1d2w,1w2m,1m1y --decrypt --encrypt --filter-properties mountpoint offsite-sm1 d/offsite/sm1
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        startAt = "daily";
      };
    };
  };

  system.activationScripts = {
    offsite-sm1.text = ''
      ${pkgs.zfs}/bin/zfs list d/offsite/sm1 >/dev/null || ${pkgs.zfs}/bin/zfs create d/offsite/sm1 -o readonly=on
    '';
  };
}
