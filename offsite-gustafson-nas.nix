{ pkgs, ... }:

{
  systemd = {
    services = {
      offsite-gustafson-nas = {
        enable = false;
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
        startAt = "daily";
      };
    };
  };

  system.activationScripts = {
    offsite-jarvis.text = ''
      ${pkgs.zfs}/bin/zfs list d/offsite/gustafson-nas >/dev/null || ${pkgs.zfs}/bin/zfs create d/offsite/gustafson-nas -o readonly=on
    '';
  };
}
