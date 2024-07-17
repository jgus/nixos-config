{ pkgs, ... }:

{
  system.activationScripts = {
    offsite-gustafson-nas.text = ''
      ${pkgs.zfs}/bin/zfs list d/offsite/gustafson-nas >/dev/null || ${pkgs.zfs}/bin/zfs create d/offsite/gustafson-nas
      ${pkgs.zfs}/bin/zfs list d/offsite/gustafson-nas/boot >/dev/null || ${pkgs.zfs}/bin/zfs create d/offsite/gustafson-nas/boot
    '';
  };

  systemd = {
    services = {
      offsite-gustafson-nas = {
        path = with pkgs; [
          openssh
          rsync
          zfs
          zfs-autobackup
        ];
        script = ''
          rsync -arP --delete gustafson-nas-landing:/boot/ /d/offsite/gustafson-nas/boot/
          zfs-autobackup --verbose --ssh-source gustafson-nas-landing --keep-source 10,1d2w,1w2m,1m1y --keep-target 10,1d2w,1w2m,1m1y --decrypt --encrypt --filter-properties mountpoint offsite-gustafson-nas d/offsite/gustafson-nas
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        startAt = "daily";
      };
    };
  };
}
