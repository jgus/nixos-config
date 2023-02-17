{ ... }:

{
  time.timeZone = "America/Denver";

  networking = {
    hostName = "pi2";
    hostId = "3743f063"; # head -c4 /dev/urandom | od -A none -t x4
  };
}
