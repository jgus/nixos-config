{ lib, ... }:
{
  homelab.services.audiobookshelf = {
    requires = [ "storage-media.mount" ];
    extraStorage = [ "audiobookshelf_metadata" ];
    container = {
      pullImage = import ../../images/audiobookshelf.nix;
      ports = [ "80" ];
      configVolume = "/config";
      volumes = [
        "/storage/media:/media"
        "${lib.homelab.storagePath "audiobookshelf_metadata"}:/metadata"
      ];
    };
  };
}
