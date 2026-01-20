{ ... }:
{
  configStorage = false;
  container = {
    readOnly = false;
    pullImage = import ../images/ipmi-server.nix;
    ports = [
      "80"
    ];
  };
}
