{ config, pkgs, ... }:
{
  docker = {
    image = "nodered/node-red";
    imageFile = pkgs.dockerTools.pullImage
      # nix-shell -p nix-prefetch-docker --run 'nix-prefetch-docker --quiet --image-name nodered/node-red --image-tag latest'
      {
        imageName = "nodered/node-red";
        imageDigest = "sha256:216e7403aab9888f7e68de9e468fed31bb9d7b2d38117c08e645095a63658a2f";
        hash = "sha256-jY0C2XQYUToeuNZybGBSy78KpY+seJUVkDsEm2LFNnw=";
        finalImageName = "nodered/node-red";
        finalImageTag = "latest";
      };
    configVolume = "/data";
    environment = {
      TZ = config.time.timeZone;
    };
    ports = [
      "1880"
    ];
  };
}
