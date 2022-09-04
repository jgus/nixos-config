{ ... }:

{
  time.timeZone = "America/Denver";

  networking = {
    hostName = "s3k2";
    hostId = "c8357f63"; # head -c4 /dev/urandom | od -A none -t x4
  };
}
