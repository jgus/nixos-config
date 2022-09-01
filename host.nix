{ ... }:

{
  time.timeZone = "America/Denver";

  networking = {
    hostName = "s3k1";
    hostId = "876d1607"; # head -c4 /dev/urandom | od -A none -t x4
  };
}
