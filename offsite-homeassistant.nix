{ pkgs, ... }:

{
  systemd = {
    services = {
      offsite-homeassistant = {
        enable = true;
        path = with pkgs; [
          hostname
          openssh
          rsync
          zfs
        ];
        script = ''
          zfs list d/offsite/homeassistant >/dev/null || zfs create d/offsite/homeassistant -o autobackup:snap-$(hostname)=true
          rsync -arP --delete \
            --exclude=/tmp \
            --exclude=/var \
            --exclude=/dev \
            --exclude=/proc \
            --exclude=/sys \
            root@ha:/ /d/offsite/homeassistant
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        startAt = "daily";
      };
    };
  };
}
