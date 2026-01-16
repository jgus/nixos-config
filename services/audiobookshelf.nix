{ config, ... }:
{
  requires = [ "storage-media.mount" ];
  container = {
    readOnly = false;
    pullImage = import ../images/audiobookshelf.nix;
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
