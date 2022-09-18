{ ... }:

{
  time.timeZone = "America/Denver";

  networking = {
    hostName = "TODO";
    hostId = "d115e877"; # head -c4 /dev/urandom | od -A none -t x4
  };
}
