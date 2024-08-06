{ config, pkgs, ... }:

let
  pw = import ./../../.secrets/passwords.nix;
  machine = import ./../../machine.nix;
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
        { address = "${machine.hostName}.home.gustafson.me"; }
      ];
    };
    upsmon.enable = false;
    users.admin = {
      actions = [ "SET" "FSD" ];
      instcmds = [ "ALL" ];
      passwordFile = toString (pkgs.writeText "password.txt" pw.ups);
    };
  };

  systemd = {
    services = {
      upsd-kick = {
        enable = true;
        description = "Restart UPSD after network address is available";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-addresses-${machine.primary_interface}.service" ];
        script = ''
          while ! systemctl restart upsd.service
          do
            sleep 1
            systemctl stop upsd.service || true
          done          
        '';
        serviceConfig = {
          Type = "oneshot";
        };
      };
    };
  };
}
