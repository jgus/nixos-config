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
      Media = { path = "/d/media"; browseable = "yes"; "read only" = "no"; };
      Backup = { path = "/d/backup"; browseable = "yes"; "read only" = "no"; };
      BackupHA = { path = "/d/backup/Home Assistant"; browseable = "yes"; "read only" = "no"; };
      Scratch = { path = "/d/scratch"; browseable = "yes"; "read only" = "no"; };
      Photos = { path = "/d/photos"; browseable = "yes"; "read only" = "no"; };
      Projects = { path = "/d/projects"; browseable = "yes"; "read only" = "no"; };
      Software = { path = "/d/software"; browseable = "yes"; "read only" = "no"; };
      Storage = { path = "/home/josh/Storage"; browseable = "yes"; "read only" = "no"; };
      Temp = { path = "/tmp/share"; browseable = "yes"; "read only" = "no"; };
      Brown = { path = "/d/external/brown"; browseable = "yes"; "read only" = "no"; };
      Gustafson = { path = "/d/external/Gustafson"; browseable = "yes"; "read only" = "no"; };
      www = { path = "/var/lib/www"; browseable = "yes"; "read only" = "no"; };
      dav = { path = "/var/lib/dav"; browseable = "yes"; "read only" = "no"; };
    };
  };
}
