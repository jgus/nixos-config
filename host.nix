{ ... }:

{
  time.timeZone = "America/Denver";

  networking = {
    hostName = "pi-67db40";
    hostId = "1f758e73"; # head -c4 /dev/urandom | od -A none -t x4
  };
}
