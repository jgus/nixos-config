{ pkgs, ... }:

let
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
in
{
  fileSystems."/tmp/share" = { device = "tmpfs"; fsType = "tmpfs"; };

  networking = {
    macvlans.eth-nas = {
      interface = "${machine.lan-interface}";
    };
    interfaces.eth-nas = {
      macAddress = addresses.services.nas.mac;
      useDHCP = true;
      #ipv4.addresses = [ { address = addresses.services.nas.ip; prefixLength = 16; } ];
    };
    firewall = {
      allowedTCPPorts = [ 5357 ]; # wsdd
      allowedUDPPorts = [ 3702 ]; # wsdd
    };
  };

  services.samba-wsdd.enable = true; # make shares visible for windows 10 clients

  services.samba = {
    enable = true;
    openFirewall = true;
    securityType = "user";
    extraConfig = ''
      interfaces = lo eth-nas
      bind interfaces only = yes
      workgroup = WORKGROUP
      server string = nas
      netbios name = nas
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
      Media = { path = "/nas/media"; browseable = "yes"; "read only" = "no"; };
      Backup = { path = "/nas/backup"; browseable = "yes"; "read only" = "no"; };
      BackupHA = { path = "/nas/backup/Home Assistant"; browseable = "yes"; "read only" = "no"; };
      TimeMachine = { path = "/nas/backup/timemachine"; browseable = "yes"; "read only" = "no"; "fruit:time machine" = "yes"; "fruit:time machine max size" = "1T"; };
      Scratch = { path = "/nas/scratch"; browseable = "yes"; "read only" = "no"; };
      Scan = { path = "/nas/scratch/scan"; browseable = "yes"; "read only" = "no"; };
      Photos = { path = "/nas/photos"; browseable = "yes"; "read only" = "no"; };
      Projects = { path = "/nas/projects"; browseable = "yes"; "read only" = "no"; };
      Software = { path = "/nas/software"; browseable = "yes"; "read only" = "no"; };
      Storage = { path = "/home/josh/Storage"; browseable = "yes"; "read only" = "no"; };
      Temp = { path = "/tmp/share"; browseable = "yes"; "read only" = "no"; };
      Brown = { path = "/nas/external/brown"; browseable = "yes"; "read only" = "no"; };
      Gustafson = { path = "/nas/external/Gustafson"; browseable = "yes"; "read only" = "no"; };
      www = { path = "/var/lib/www"; browseable = "yes"; "read only" = "no"; };
      dav = { path = "/var/lib/dav"; browseable = "yes"; "read only" = "no"; };
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
