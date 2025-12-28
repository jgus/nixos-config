{ config, pkgs, ... }:
{
  requires = [ "storage-media.mount" ];
  docker = {
    pullImage =
      # nix-shell -p nix-prefetch-docker --run 'nix-prefetch-docker --quiet --image-name ghcr.io/advplyr/audiobookshelf --image-tag latest'
      {
        imageName = "ghcr.io/advplyr/audiobookshelf";
        imageDigest = "sha256:a52dc5db694a5bf041ce38f285dd6c6a660a4b1b21e37ad6b6746433263b2ae5";
        hash = "sha256-LMHpQiv8ygEv728Frn1NMVVGHuP2Os4vKt3CnMXL6pk=";
        finalImageName = "ghcr.io/advplyr/audiobookshelf";
        finalImageTag = "latest";
      };
    environment = {
      TZ = config.time.timeZone;
    };
    ports = [ "80" ];
    configVolume = "/config";
    extraStorage = [ "audiobookshelf_metadata" ];
    volumes = storagePath: [
      "/storage/media:/media"
      "${storagePath "audiobookshelf_metadata"}:/metadata"
    ];
  };
}
