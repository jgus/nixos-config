{ pkgs, ... }:

{
  systemd = {
    services = {
      offsite-homeassistant = {
        path = with pkgs; [
          openssh
          rsync
        ];
        script = ''
          rsync -arP --delete \
            --exclude=/tmp \
            --exclude=/var \
            --exclude=/dev \
            --exclude=/proc \
            --exclude=/sys \
            root@homeassistant:/ /d/offsite/homeassistant
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        startAt = "daily";
      };
    };
  };

  system.activationScripts = {
    offsite-homeassistant.text = ''
      ${pkgs.zfs}/bin/zfs list d/offsite/homeassistant >/dev/null || ${pkgs.zfs}/bin/zfs create d/offsite/homeassistant -o autobackup:snap-$(${pkgs.hostname}/bin/hostname)=true
    '';
  };
}
