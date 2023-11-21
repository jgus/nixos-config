{ ... }:

{
  time.timeZone = "America/Denver";

  networking = {
    hostName = "pi-8df558";
    hostId = "a1ad01d4"; # head -c4 /dev/urandom | od -A none -t x4
  };
}
