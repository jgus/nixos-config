{ ... }:
{
  requires = [ "storage-media.mount" ];
  container = {
    pullImage = import ../images/audiobookshelf.nix;
    ports = [ "80" ];
    configVolume = "/config";
    extraStorage = [ "audiobookshelf_metadata" ];
    volumes = storagePath: [
      "/storage/media:/media"
      "${storagePath "audiobookshelf_metadata"}:/metadata"
    ];
  };
}
