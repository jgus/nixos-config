{ config, lib, pkgs, ... }:
{
  homelab.services.onlyoffice = {
    container = {
      pullImage = import ../../images/documentserver.nix;
      readOnly = false;
      environmentFiles = [ config.sops.secrets."onlyoffice".path ];
      configVolume = "/var/www/onlyoffice/Data";
      volumes = [
        "${pkgs.vista-fonts}:/usr/share/fonts/truetype/vista-fonts:ro"
      ];
      ports = [ "80" ];
    };
  };

  nixpkgs = lib.mkIf config.homelab.services.onlyoffice.enable {
    config.allowUnfree = true;
  };

  sops = lib.mkIf config.homelab.services.onlyoffice.enable {
    secrets.onlyoffice = { };
  };
}
