{ ... }:
{
  homelab.services.ipmi-server = {
    configStorage = false;
    container = {
      pullImage = import ../../images/ipmi-server.nix;
      readOnly = false;
      ports = [
        "80"
      ];
    };
  };
}
