{ ... }:
{
  homelab.services.node-red = {
    configStorage = false;
    container = {
      pullImage = import ../../images/ntp.nix;
      readOnly = true;
      environment = {
        NTP_SERVERS = "time.cloudflare.com";
        ENABLE_NTS = "true";
      };
      tmpFs = [
        "/etc/chrony"
        "/run/chrony"
        "/var/lib/chrony"
      ];
      ports = [
        "123/udp"
      ];
    };
  };
}
