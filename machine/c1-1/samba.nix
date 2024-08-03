{ pkgs, ... }:

let
  name = "c1"; # "nas"
in
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
      server string = ${name}
      netbios name = ${name}
      security = user 
      guest account = nobody
      map to guest = bad user
      inherit permissions = yes
      vfs objects = fruit streams_xattr
      fruit:metadata = stream
      fruit:veto_appledouble = yes
      fruit:nfs_aces = no
      fruit:wipe_intentionally_left_blank_rfork = yes
      fruit:delete_empty_adfiles = yes
    '';
    shares = {
      josh = { path = "/home/josh"; browseable = "yes"; "read only" = "no"; };
      # Media = { path = "/d/media"; browseable = "yes"; "read only" = "no"; };
      # Backup = { path = "/d/backup"; browseable = "yes"; "read only" = "no"; };
      # BackupHA = { path = "/d/backup/Home Assistant"; browseable = "yes"; "read only" = "no"; };
      # TimeMachine = { path = "/d/backup/timemachine"; browseable = "yes"; "read only" = "no"; "fruit:time machine" = "yes"; "fruit:time machine max size" = "1T"; };
      Scratch = { path = "/d/scratch"; browseable = "yes"; "read only" = "no"; };
      # Scan = { path = "/d/scratch/scan"; browseable = "yes"; "read only" = "no"; };
      # Photos = { path = "/d/photos"; browseable = "yes"; "read only" = "no"; };
      # Projects = { path = "/d/projects"; browseable = "yes"; "read only" = "no"; };
      # Software = { path = "/d/software"; browseable = "yes"; "read only" = "no"; };
      # Storage = { path = "/home/josh/Storage"; browseable = "yes"; "read only" = "no"; };
      Temp = { path = "/tmp/share"; browseable = "yes"; "read only" = "no"; };
      # Brown = { path = "/d/external/brown"; browseable = "yes"; "read only" = "no"; };
      # Gustafson = { path = "/d/external/Gustafson"; browseable = "yes"; "read only" = "no"; };
      # www = { path = "/var/lib/www"; browseable = "yes"; "read only" = "no"; };
      # dav = { path = "/var/lib/dav"; browseable = "yes"; "read only" = "no"; };
    };
  };

  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
    extraServiceFiles = {
      smb = ''
        <?xml version="1.0" standalone='no'?>
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">%h</name>
          <service>
            <type>_smb._tcp</type>
            <port>445</port>
          </service>
          <service>
            <type>_device-info._tcp</type>
            <port>0</port>
            <txt-record>model=TimeCapsule8,119</txt-record>
          </service>
          <service>
            <type>_adisk._tcp</type>
            <txt-record>dk0=adVN=timemachine,adVF=0x82</txt-record>
            <txt-record>sys=waMa=0,adVF=0x100</txt-record>
          </service>
        </service-group>
      '';
    };
  };
}