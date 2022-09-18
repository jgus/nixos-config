{ ... }:

{
  time.timeZone = "America/Denver";

  networking = {
    hostName = "sm1";
    hostId = "e7818f0a"; # head -c4 /dev/urandom | od -A none -t x4
  };
}
