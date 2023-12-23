{ config, pkgs, ... }:

{
  imports = [ ./docker.nix ];

  system.activationScripts = {
    home-assistantSetup.text = ''
      ${pkgs.zfs}/bin/zfs list r/varlib/home-assistant >/dev/null 2>&1 || ( ${pkgs.zfs}/bin/zfs create r/varlib/home-assistant && chown home-assistant:home-assistant /var/lib/home-assistant )
    '';
  };

  networking.firewall.allowedTCPPorts = [ 8123 ];

  systemd = {
    services = {
      home-assistant = {
        enable = true;
        description = "Home Assistant";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        path = [ pkgs.docker ];
        script = ''
          docker container stop home-assistant >/dev/null 2>&1 || true ; \
          docker container rm -f home-assistant >/dev/null 2>&1 || true ; \
          docker run --rm --name home-assistant \
            --privileged \
            --net host \
            -e PUID="$(id -u home-assistant)" \
            -e PGID="$(id -g home-assistant)" \
            -e TZ="$(timedatectl show -p Timezone --value)" \
            -e VERSION=latest \
            -v /var/lib/home-assistant:/config \
            -v /run/dbus:/run/dbus:ro \
            ghcr.io/home-assistant/home-assistant:stable
        '';
        serviceConfig = {
          Restart = "on-failure";
        };
      };
      home-assistant-update = {
        path = [ pkgs.docker ];
        script = ''
          if docker pull ghcr.io/home-assistant/home-assistant:stable | grep "Status: Downloaded"
          then
            systemctl restart home-assistant
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
