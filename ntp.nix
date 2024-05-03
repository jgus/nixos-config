{ config, pkgs, ... }:

{
  imports = [ ./docker.nix ];

  networking.firewall.allowedUDPPorts = [ 123 ];

  systemd = {
    services = {
      ntp = {
        enable = true;
        description = "NTP";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        path = [ pkgs.docker ];
        script = ''
          docker container stop ntp >/dev/null 2>&1 || true ; \
          docker container rm -f ntp >/dev/null 2>&1 || true ; \
          docker run --rm --name ntp \
            -p 123/udp \
            --read-only                          \
            --tmpfs=/etc/chrony:rw,mode=1750     \
            --tmpfs=/run/chrony:rw,mode=1750     \
            --tmpfs=/var/lib/chrony:rw,mode=1750 \
            cturra/ntp
        '';
        serviceConfig = {
          Restart = "no";
        };
      };
      ntp-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull cturra/ntp | grep "Status: Downloaded"
          then
            systemctl restart ntp
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
