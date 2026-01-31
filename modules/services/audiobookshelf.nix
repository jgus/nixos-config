{ lib, ... }:
{
  homelab.services.audiobookshelf = {
    requires = [ "storage-media.mount" ];
    extraStorage = [ "audiobookshelf_metadata" ];
    container = {
      pullImage = import ../../images/audiobookshelf.nix;
      configVolume = "/config";
      volumes = [
        "/storage/media:/media"
        "${lib.homelab.storagePath "audiobookshelf_metadata"}:/metadata"
      ];
      ports = [ "80" ];
    };
  };
}
