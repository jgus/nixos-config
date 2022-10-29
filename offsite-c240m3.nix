{ pkgs, ... }:

{
  systemd = {
    services = {
      offsite-c240m3 = {
        path = with pkgs; [
          openssh
          zfs
          zfs-autobackup
        ];
        script = ''
          zfs-autobackup --verbose --ssh-source root@c240m3 --keep-source 10,1d2w,1w2m,1m1y --keep-target 10,1d2w,1w2m,1m1y --decrypt --encrypt --filter-properties mountpoint offsite-c240m3 d/offsite/c240m3
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        startAt = "daily";
      };
    };
  };

  system.activationScripts = {
    offsite-c240m3.text = ''
      ${pkgs.zfs}/bin/zfs list d/offsite/c240m3 >/dev/null || ${pkgs.zfs}/bin/zfs create d/offsite/c240m3 -o readonly=on
    '';
  };
}
