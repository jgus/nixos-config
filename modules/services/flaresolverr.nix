{ ... }:
{
  homelab.services.flaresolverr = {
    configStorage = false;
    container = {
      pullImage = import ../../images/flaresolverr.nix;
      readOnly = false;
      ports = [
        "8191"
      ];
    };
  };
}
