{ ... }:
{
  container = {
    pullImage = import ../images/node-red.nix;
    configVolume = "/data";
    ports = [
      "1880"
    ];
  };
}
