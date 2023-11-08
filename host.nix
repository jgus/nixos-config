{ ... }:

{
  time.timeZone = "America/Denver";

  networking = {
    hostName = "pi-67dbcd";
    hostId = "da46f0cf"; # head -c4 /dev/urandom | od -A none -t x4
  };
}
