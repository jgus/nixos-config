{ config, lib, ... }:
{
  homelab.services.open-webui = {
    container = {
      pullImage = import ../../images/open-webui.nix;
      readOnly = false;
      environmentFiles = [
        config.sops.secrets."openWebui".path
      ];
      configVolume = "/app/backend/data";
      ports = [
        "8080"
      ];
    };
  };

  sops = lib.mkIf config.homelab.services.garage.enable {
    secrets."openWebui" = { };
  };
}
