{ config, pkgs, ... }:

{
  imports = [ ./docker.nix ];

  users = {
    groups.plex = { gid = 193; };
    users.plex = {
      uid = 193;
      isSystemUser = true;
      group = "plex";
    };
  };

  system.activationScripts = {
    plexSetup.text = ''
      ${pkgs.zfs}/bin/zfs list rpool/varlib/plex >/dev/null 2>&1 || ( ${pkgs.zfs}/bin/zfs create rpool/varlib/plex && chown plex:plex /var/lib/plex )
    '';
  };

  environment.etc = {
    ".secrets/plex-smb".source = ./.secrets/plex-smb;
  };

  fileSystems."/shares/plex/media" = {
      device = "//nas/Media";
      fsType = "cifs";
      options = let
        # this line prevents hanging on network split
        automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
      in ["${automount_opts},credentials=/etc/.secrets/plex-smb,uid=${toString(config.users.users.plex.uid)},gid=${toString(config.users.groups.plex.gid)}"];
  };
  fileSystems."/shares/plex/photos" = {
      device = "//nas/Photos";
      fsType = "cifs";
      options = let
        # this line prevents hanging on network split
        automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
      in ["${automount_opts},credentials=/etc/.secrets/plex-smb,uid=${toString(config.users.users.plex.uid)},gid=${toString(config.users.groups.plex.gid)}"];
  };

  networking.firewall.allowedTCPPorts = [ 32400 ];

  systemd = {
    services = {
      plex = {
        enable = true;
        description = "Plex Media Server";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        path = [ pkgs.docker ];
        script = ''
          docker run --rm --name plex \
            --net host \
            --gpus all \
            --device /dev/dri:/dev/dri \
            -e PUID="$(id -u plex)" \
            -e PGID="$(id -g plex)" \
            -e TZ="$(timedatectl show -p Timezone --value)" \
            -e VERSION=latest \
            -v /var/lib/plex:/config \
            -v /shares/plex/media:/media \
            -v /shares/plex/photos:/shares/photos \
            --tmpfs /tmp \
            lscr.io/linuxserver/plex
          '';
        serviceConfig = {
          Restart = "on-failure";
        };
      };
    };
  };
}
