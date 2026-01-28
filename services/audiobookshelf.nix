{ lib, ... }:
{
  requires = [ "storage-media.mount" ];
  container = {
    pullImage = import ../images/audiobookshelf.nix;
    ports = [ "80" ];
    configVolume = "/config";
    extraStorage = [ "audiobookshelf_metadata" ];
    volumes = [
      "/storage/media:/media"
      "${lib.homelab.storagePath "audiobookshelf_metadata"}:/metadata"
    ];
  };
}
