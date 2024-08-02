{ config, pkgs, ... }:

let
  image = "lscr.io/linuxserver/syncthing";
  mac-addresses = import ./mac-addresses.nix;
in
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

  virtualisation.oci-containers.containers.syncthing = {
    image = "${image}";
    autoStart = true;
    ports = [
      "8384:8384"
      "22000:22000"
      "21027:21027/udp"
    ];
    environment = {
      PUID = "${toString config.users.users.josh.uid}";
      PGID = "${toString config.users.groups.users.gid}";
      TZ = "${config.time.timeZone}";
      UMASK_SET = "002";
    };
    volumes = [
      "/var/lib/syncthing:/config"
      "/home/josh/sync:/shares/Sync"
      "/d/photos:/shares/Photos"
      "/d/software/Tools:/shares/Tools"
      "/d/media/Comics:/shares/Comics"
      "/d/media/Music:/shares/Music"
    ];
    extraOptions = [
      "--network=dhcp-net"
      "--mac-address=${mac-addresses.services.syncthing}"
    ];
  };

  systemd = {
    services = {
      syncthing-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull ${image} | grep "Status: Downloaded"
          then
            systemctl restart docker-syncthing
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
