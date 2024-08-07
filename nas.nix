{ pkgs, ... }:

let
  machine = import ./machine.nix;
in
if machine.nas-host then
{
  services.nfs.server.enable = true;
  networking.firewall.allowedTCPPorts = [ 2049 ];
  
  fileSystems."/nas" = {
    device = "/d";
    options = [ "rbind" ];
  };

  services.nfs.server.exports = ''
    /nas 172.22.1.0/22(rw,crossmnt,no_root_squash)
  '';
}
else
{
  services.rpcbind.enable = true;
  
  environment.systemPackages = with pkgs; [
    nfs-utils
  ];

  systemd.mounts = [
    {
      type = "nfs";
      mountConfig = {
        Options = "noatime";
      };
      what = "nas:/nas";
      where = "/nas";
    }
  ];

  systemd.automounts = [
    {
      wantedBy = [ "multi-user.target" ];
      automountConfig = {
        TimeoutIdleSec = "600";
      };
      where = "/nas";
    }
  ];
}
