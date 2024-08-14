{ config, pkgs, ... }:

let
  pw = import ./../../.secrets/passwords.nix;
  machine = import ./../../machine.nix;
  addresses = import ./../../addresses.nix;
in
{
  power.ups = {
    enable = true;
    mode = "netserver";
    openFirewall = true;
    ups.net = {
      driver = "usbhid-ups";
      port = "auto";
      description = "Network Rack";
    };
    upsd = {
      enable = true;
      listen = [
        { address = "localhost"; }
        { address = addresses.servers."${machine.hostName}".ip; }
      ];
    };
    upsmon.enable = false;
    users.admin = {
      actions = [ "SET" "FSD" ];
      instcmds = [ "ALL" ];
      passwordFile = toString (pkgs.writeText "password.txt" pw.ups);
    };
  };
}
