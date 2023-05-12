{ ... }:

{
  time.timeZone = "America/Denver";

  networking = {
    hostName = "gusbox-pi";
    hostId = "adfce7d8"; # head -c4 /dev/urandom | od -A none -t x4
  };
}
