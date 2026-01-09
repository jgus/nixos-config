{ config, ... }:
{
  container = {
    readOnly = false;
    pullImage = import ../images/open-webui.nix;
    ports = [
      "8080"
    ];
    configVolume = "/app/backend/data";
    environmentFiles = [
      config.sops.secrets."openWebui".path
    ];
  };
  extraConfig = {
    sops.secrets."openWebui" = { };
  };
}
