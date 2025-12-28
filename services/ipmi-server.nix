{ config, pkgs, ... }:
{
  configStorage = false;
  docker = {
    image = "mneveroff/ipmi-server";
    imageFile = pkgs.dockerTools.pullImage
      # nix-shell -p nix-prefetch-docker --run 'nix-prefetch-docker --quiet --image-name mneveroff/ipmi-server --image-tag latest'
      {
        imageName = "mneveroff/ipmi-server";
        imageDigest = "sha256:5d9a5bf594f49973b1524659caa814a68f78771a9faeefe45cbe3bc94b152806";
        hash = "sha256-QksyapVvFSMSR9ROu9LEFxjdjE7QmceuPcyo/za8K1M=";
        finalImageName = "mneveroff/ipmi-server";
        finalImageTag = "latest";
      };
    environment = {
      TZ = config.time.timeZone;
    };
    ports = [
      "80"
    ];
  };
}
