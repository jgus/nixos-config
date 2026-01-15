{ config, machine, myLib, ... }:
{
  power.ups = {
    enable = true;
    mode = "netserver";
    openFirewall = true;
    ups = {
      net = {
        driver = "usbhid-ups";
        port = "auto";
        description = "Network Rack";
      };
      server = {
        driver = "snmp-ups";
        description = "Server Rack";
        port = "server-ups";
        directives = [
          "snmp_version=v3"
          "secName=nut"
        ];
      };
    };
    upsd = {
      enable = true;
      listen = [
        { address = "localhost"; }
        { address = myLib.nameToIp.${machine.hostName}; }
        { address = myLib.nameToIp6.${machine.hostName}; }
      ];
    };
    upsmon.enable = false;
    users.admin = {
      actions = [ "SET" "FSD" ];
      instcmds = [ "ALL" ];
      passwordFile = config.sops.secrets.ups.path;
    };
  };
  sops.secrets.ups = { };
}
