{ config, ... }:
{
  requires = [ "storage-media.mount" ];
  docker = {
    image = "ghcr.io/advplyr/audiobookshelf";
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
