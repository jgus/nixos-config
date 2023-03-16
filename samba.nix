{ pkgs, ... }:

{
  fileSystems."/tmp/share" = { device = "tmpfs"; fsType = "tmpfs"; };

  networking.firewall = {
    allowedTCPPorts = [ 5357 ]; # wsdd
    allowedUDPPorts = [ 3702 ]; # wsdd
  };

  services.samba-wsdd.enable = true; # make shares visible for windows 10 clients

  services.samba = {
    enable = true;
    openFirewall = true;
    securityType = "user";
    extraConfig = ''
      workgroup = WORKGROUP
      server string = nas
      netbios name = nas
      security = user 
      guest account = nobody
      map to guest = bad user
    '';
    shares = {
      josh = { path = "/home/josh"; browseable = "yes"; "read only" = "no"; };
    };
  };
}
