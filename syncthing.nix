{ pkgs, ... }:

{
  imports = [ ./docker.nix ];

  networking.firewall = {
    allowedTCPPorts = [ 8384 22000 ];
    allowedUDPPorts = [ 21027 ];
  };

  system.activationScripts = {
    syncthingSetup.text = ''
      ${pkgs.zfs}/bin/zfs list r/varlib/syncthing >/dev/null 2>&1 || ( ${pkgs.zfs}/bin/zfs create r/varlib/syncthing && chown josh:users /var/lib/syncthing )
      ${pkgs.zfs}/bin/zfs list r/varlib/syncthing/index-v0.14.0.db >/dev/null 2>&1 || ( ${pkgs.zfs}/bin/zfs create r/varlib/syncthing/index-v0.14.0.db && chown josh:users /var/lib/syncthing/index-v0.14.0.db )
    '';
  };

  systemd = {
    services = {
      syncthing = {
        enable = true;
        description = "Syncthing";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        path = [ pkgs.docker ];
        script = ''
          docker container stop syncthing >/dev/null 2>&1 || true ; \
          docker container rm -f syncthing >/dev/null 2>&1 || true ; \
          docker run --rm --name syncthing \
            -p 8384:8384 \
            -p 22000:22000 \
            -p 21027:21027/udp \
            -e PUID=$(id -u josh) \
            -e PGID=$(id -g josh) \
            -e TZ=$(timedatectl show -p Timezone --value) \
            -e UMASK_SET=002 \
            -v /var/lib/syncthing:/config \
            -v /home/josh/sync:/shares/Sync \
            -v /d/photos:/shares/Photos \
            -v /d/software/Tools:/shares/Tools \
            -v /d/media/Comics:/shares/Comics \
            -v /d/media/Music:/shares/Music \
            lscr.io/linuxserver/syncthing
        '';
        serviceConfig = {
          Restart = "always";
        };
      };
      syncthing-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull lscr.io/linuxserver/syncthing | grep "Status: Downloaded"
          then
            systemctl restart syncthing
          fi
        '';
        serviceConfig = {
          Type = "oneshot";
        };
        startAt = "hourly";
      };
    };
  };
}
