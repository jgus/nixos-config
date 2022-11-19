{ pkgs, ... }:

{
  boot = {
    supportedFilesystems = [
      "zfs"
    ];
    zfs = {
      devNodes = "/dev/disk/by-path";
      extraPools = [ "rpool" "s" "d" ];
    };
  };

  environment.systemPackages = with pkgs; [
    zfs
    zfs-autobackup
  ];

  services.zfs.autoScrub.enable = true;

  systemd = {
    services = {
      zfs-auto-snapshot = {
        path = with pkgs; [ hostname zfs zfs-autobackup ];
        script = "zfs-autobackup --keep-source 10,1h2d,1d2w,1w2m,1m1y snap-$(hostname)";
        serviceConfig = {
          Type = "oneshot";
        };
        startAt = "hourly";
      };
    };
  };
}
