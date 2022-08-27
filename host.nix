{ ... }:

{
  time.timeZone = "America/Denver";

  networking = {
    hostName = "TODO";
    hostId = "HOSTID"; # head -c4 /dev/urandom | od -A none -t x4
  };
}
