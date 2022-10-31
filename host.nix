{ ... }:

{
  time.timeZone = "America/Denver";

  networking = {
    hostName = "sm1";
    hostId = "d115e877"; # head -c4 /dev/urandom | od -A none -t x4
    defaultGateway = {
      address = "172.22.0.1";
      interface = "eno1";
    };
  };
}
