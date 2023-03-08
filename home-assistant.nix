{ pkgs, ... }:

{
  imports = [
    ./cec.nix
    ./docker.nix
  ];

  networking.firewall = {
    allowedTCPPorts = [ 8123 ];
  };

  systemd = {
    services = {
      home-assistant = {
        enable = false;
        description = "Home Assistant";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        path = [ pkgs.docker ];
        script = ''
          docker container stop home-assistant >/dev/null 2>&1 || true ; \
          docker run --rm --name home-assistant \
            --privileged \
            -p 8123 \
            -e TZ=$(timedatectl show -p Timezone --value) \
            -v /var/lib/home-assistant:/config \
            --network=host \
            --device=/dev/vchiq \
            $(for d in /dev/tty*; do echo --device=$d; done) \
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
