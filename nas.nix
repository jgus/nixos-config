{ pkgs, ... }:

let
  service = "nas";
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
in
if (machine.hostName == addresses.records."${service}".host) then
{
  services.nfs.server.enable = true;
  networking.firewall = {
    allowedTCPPorts = [
      2049 # rbind
      5357 # wsdd
    ];
    allowedUDPPorts = [ 3702 ]; # wsdd
  };
  
  fileSystems."/storage/tmp" = { device = "tmpfs"; fsType = "tmpfs"; };

  services.nfs.server.exports = ''
    /home 172.22.1.0/24(rw,crossmnt,no_root_squash)
  '';

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
      Media = { path = "/storage/media"; browseable = "yes"; "read only" = "no"; };
      Backup = { path = "/storage/backup"; browseable = "yes"; "read only" = "no"; };
      BackupHA = { path = "/storage/backup/Home Assistant"; browseable = "yes"; "read only" = "no"; };
      TimeMachine = { path = "/storage/backup/timemachine"; browseable = "yes"; "read only" = "no"; "fruit:time machine" = "yes"; "fruit:time machine max size" = "1T"; };
      Scratch = { path = "/storage/scratch"; browseable = "yes"; "read only" = "no"; };
      Scan = { path = "/storage/scratch/scan"; browseable = "yes"; "read only" = "no"; };
      Photos = { path = "/storage/photos"; browseable = "yes"; "read only" = "no"; };
      Projects = { path = "/storage/projects"; browseable = "yes"; "read only" = "no"; };
      Software = { path = "/storage/software"; browseable = "yes"; "read only" = "no"; };
      Storage = { path = "/home/josh/Storage"; browseable = "yes"; "read only" = "no"; };
      Temp = { path = "/storage/tmp"; browseable = "yes"; "read only" = "no"; };
      Brown = { path = "/storage/external/brown"; browseable = "yes"; "read only" = "no"; };
      Gustafson = { path = "/storage/external/Gustafson"; browseable = "yes"; "read only" = "no"; };
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
else
{
  services.rpcbind.enable = true;
  
  environment.systemPackages = with pkgs; [
    nfs-utils
  ];

  systemd.mounts = (map (x: {
    type = "nfs";
    mountConfig = {
      Options = "noatime";
    };
    what = "nfs:/${x}";
    where = "/${x}";
  }) [ "home" ]);

  systemd.automounts = (map (x: {
    wantedBy = [ "multi-user.target" ];
    automountConfig = {
      TimeoutIdleSec = "600";
    };
    where = "/${x}";
  }) [ "home" ]);
}
