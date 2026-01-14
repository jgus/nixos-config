{ pkgs, ... }:
{
  nixpkgs.overlays = [
    (self: super: {
      libcec = super.libcec.override { withLibraspberrypi = true; };
    })
  ];

  environment.systemPackages = [ pkgs.libcec ];

  networking.firewall = {
    allowedUDPPorts = [ 9526 ];
  };

  systemd = {
    services = {
      cec = {
        enable = true;
        description = "CEC-Client";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        path = [ pkgs.socat pkgs.libcec ];
        script = ''
          socat -u UDP6-LISTEN:9526,reuseaddr,fork,ipv6only=0 STDOUT | cec-client
        '';
        serviceConfig = {
          Restart = "no";
        };
      };
    };
  };
}
