{ pkgs, ... }:

{
  system.activationScripts = {
    offsite-josh-ws.text = ''
      ${pkgs.zfs}/bin/zfs list d/offsite/josh-ws >/dev/null || ${pkgs.zfs}/bin/zfs create d/offsite/josh-ws
    '';
  };

  systemd = {
    services = {
      offsite-josh-ws = {
        path = with pkgs; [
          openssh
          zfs
          zfs-autobackup
        ];
        script = ''
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
