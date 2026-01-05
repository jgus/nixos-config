{ ... }:
let
  pw = import ./../.secrets/passwords.nix;
in
{
  container = {
    readOnly = false;
    pullImage = import ../images/open-webui.nix;
    ports = [
      "8080"
    ];
    configVolume = "/app/backend/data";
    environment = {
      WEBUI_SECRET_KEY = pw.openWebui.secretKey;
    };
  };
}
