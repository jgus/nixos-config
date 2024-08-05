{ ... }:

{
  services.nfs.server.enable = true;
  networking.firewall.allowedTCPPorts = [ 2049 ];
  
  fileSystems."/export" = {
    device = "/d";
    options = [ "rbind" ];
  };

  services.nfs.server.exports = ''
    /export 172.22.0.0/22(rw,crossmnt,no_root_squash)
  '';
}
