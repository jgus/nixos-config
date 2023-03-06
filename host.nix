{ ... }:

{
  time.timeZone = "America/Denver";

  networking = {
    hostName = "josh-ws";
    hostId = "d39bf316"; # head -c4 /dev/urandom | od -A none -t x4
  };
}
