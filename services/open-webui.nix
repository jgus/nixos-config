{ ... }:
{
  container = {
    pullImage = import ../images/open-webui.nix;
    ports = [
      "8080"
    ];
    configVolume = "/app/backend/data";
  };
}
