{ pkgs, ... }:

{
  systemd = {
    services = {
      offsite-pihole = {
        path = with pkgs; [
          openssh
          rsync
        ];
        script = ''
          rsync -arxP --delete \
            --exclude=/tmp \
            --exclude=/var \
            root@pi.hole:/ /d/offsite/pihole
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        startAt = "daily";
      };
    };
  };

  system.activationScripts = {
    offsite-pihole.text = ''
      ${pkgs.zfs}/bin/zfs list d/offsite/pihole >/dev/null || ${pkgs.zfs}/bin/zfs create d/offsite/pihole -o autobackup:snap-$(${pkgs.hostname}/bin/hostname)=true
    '';
  };
}
