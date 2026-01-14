{ config, pkgs, machine, ... }:
{
  boot = {
    # kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    supportedFilesystems = [
      "zfs"
    ];
    zfs = {
      devNodes = "/dev/disk/by-path";
      extraPools = [ "r" ] ++ machine.zfs-pools;
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
      zfs-pool-status = {
        path = with pkgs; [ hostname zfs sharutils msmtp ];
        script = ''
          EMAIL_TO=($(cat ${config.sops.secrets.admin_email.path}))
          if zpool status | grep DEGRADED
          then
            for to in "''${EMAIL_TO[@]}"
            do
              (echo "subject: Degraded ZFS Pool on $(hostname)" && uuencode <(zpool status) status.txt) | msmtp "''${to}"
            done
          fi
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        startAt = "daily";
      };
    };
  };

  sops.secrets.admin_email = { };
}
