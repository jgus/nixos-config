{ config, pkgs, ... }:

{
  imports = [ ./docker.nix ];

  system.activationScripts = {
    piholeSetup.text = ''
      ${pkgs.docker}/bin/docker network create -d macvlan --subnet=172.22.0.0/15 --gateway=172.22.0.1 --ip-range=172.22.202.0/16 -o parent=enp10s0f1 macnet >/dev/null 2>&1 || true
      ${pkgs.docker}/bin/docker network create -d bridge --subnet=192.168.22.0/24 bridge2 >/dev/null 2>&1 || true
      ${pkgs.zfs}/bin/zfs list r/varlib/pihole >/dev/null 2>&1 || ( ${pkgs.zfs}/bin/zfs create r/varlib/pihole )
      mkdir -p /var/lib/pihole/etc-pihole
      mkdir -p /var/lib/pihole/etc-dnsmasq.d
    '';
  };

  environment.etc = {
    ".secrets/pihole".source = ./.secrets/pihole;
  };

  systemd = {
    services = {
      pihole = {
        enable = true;
        description = "Pi-hole";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        path = [ pkgs.docker ];
        script = ''
          docker stop pihole || true
          docker rm pihole || true
          docker create --name pihole \
            --net macnet \
            --ip="172.22.0.2" \
            -e TZ="$(timedatectl show -p Timezone --value)" \
            -e WEBPASSWORD="$(cat /etc/.secrets/pihole)" \
            -v /var/lib/pihole/etc-pihole:/etc/pihole \
            -v /var/lib/pihole/etc-dnsmasq.d:/etc/dnsmasq.d \
            --tmpfs /tmp \
            --cap-add=NET_ADMIN \
            pihole/pihole
          docker network connect --ip 192.168.22.2 bridge2 pihole
          docker start pihole -ia
        '';
        preStop = ''
          docker stop pihole
          docker rm pihole
        '';
        serviceConfig = {
          Restart = "no";
        };
      };
      pihole-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull pihole/pihole | grep "Status: Downloaded"
          then
            systemctl restart pihole
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
