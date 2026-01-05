{ ... }:
{
  configStorage = false;
  container = {
    pullImage = import ../images/ntp.nix;
    ports = [
      "123/udp"
    ];
    environment = {
      NTP_SERVERS = "time.cloudflare.com";
      ENABLE_NTS = "true";
    };
    readOnly = true;
    tmpFs = [
      "/etc/chrony"
      "/run/chrony"
      "/var/lib/chrony"
    ];
  };
}
