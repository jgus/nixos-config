{ config, pkgs, ... }:

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
    upsmon.enable = false;
    users.admin = {
      actions = [ "SET" "FSD" ];
      instcmds = [ "ALL" ];
      passwordFile = toString (pkgs.writeText "password.txt" "testtest");
    };
  };
}
