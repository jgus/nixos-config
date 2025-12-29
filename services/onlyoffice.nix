{ pkgs, ... }:
let
  pw = import ./../.secrets/passwords.nix;
in
[
  {
    name = "onlyoffice";
    container = {
      pullImage = {
        imageName = "onlyoffice/documentserver";
        imageDigest = "sha256:fd00acbbbde3d8b1ead9b933aafa7c2df77e62c48b1b171886e6bef343c13882";
        hash = "sha256-3gOCR6brSvU0mVVI0rcNEXdK+vZu0TT3iqBoqFIpNbI=";
        finalImageName = "onlyoffice/documentserver";
        finalImageTag = "latest";
      };
      configVolume = "/var/www/onlyoffice/Data";
      ports = [ "80" ];
      environment = {
        JWT_SECRET = pw.onlyoffice;
      };
      volumes = [
        "${pkgs.vista-fonts}:/usr/share/fonts/truetype/vista-fonts:ro"
      ];
    };
    extraConfig = {
      nixpkgs.config.allowUnfree = true;
    };
  }
]
