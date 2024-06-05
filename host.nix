{ ... }:

{
  time.timeZone = "America/Denver";

  networking = {
    hostName = "pi-67cba1";
    hostId = "62c05afa"; # head -c4 /dev/urandom | od -A none -t x4
  };
}
