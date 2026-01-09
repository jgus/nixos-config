{ config, pkgs, ... }:
[
  {
    name = "onlyoffice";
    container = {
      readOnly = false;
      pullImage = import ../images/documentserver.nix;
      configVolume = "/var/www/onlyoffice/Data";
      ports = [ "80" ];
      environmentFiles = [ config.sops.secrets."onlyoffice".path ];
      volumes = [
        "${pkgs.vista-fonts}:/usr/share/fonts/truetype/vista-fonts:ro"
      ];
    };
    extraConfig = {
      nixpkgs.config.allowUnfree = true;
      sops.secrets.onlyoffice = { };
    };
  }
]
