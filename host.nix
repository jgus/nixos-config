{ ... }:

{
  time.timeZone = "America/Denver";

  networking = {
    hostName = "pi-67dc75";
    hostId = "39a18894"; # head -c4 /dev/urandom | od -A none -t x4
  };
}
