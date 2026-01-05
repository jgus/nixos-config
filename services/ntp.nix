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
    extraOptions = [
      "--tmpfs=/etc/chrony:rw,mode=1750"
      "--tmpfs=/run/chrony:rw,mode=1750"
      "--tmpfs=/var/lib/chrony:rw,mode=1750"
    ];
  };
}
