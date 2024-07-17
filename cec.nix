{ pkgs, ... }:

{
  nixpkgs.overlays = [
    (self: super: {
      libcec = super.libcec.override { withLibraspberrypi = true; };
    }
    )
  ];
  
  environment.systemPackages = [
    pkgs.libcec
  ];

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
        path = [ pkgs.netcat pkgs.libcec ];
        script = ''
          nc -ulk 9526 | cec-client
          '';
        serviceConfig = {
          Restart = "no";
        };
      };
    };
  };
}
