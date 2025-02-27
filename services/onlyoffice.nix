{ config, pkgs, ... }:
let
  pw = import ./../.secrets/passwords.nix;
in
[
  {
    name = "onlyoffice";
    docker = {
      image = "onlyoffice/documentserver";
      configVolume = "/var/www/onlyoffice/Data";
      ports = [ "80" ];
      environment = {
        JWT_SECRET = pw.onlyoffice;
      };
      volumes = [
        "${pkgs.vistafonts}:/usr/share/fonts/truetype/vistafonts:ro"
      ];
    };
    extraConfig = {
      nixpkgs.config.allowUnfree = true;
    };
  }
]
