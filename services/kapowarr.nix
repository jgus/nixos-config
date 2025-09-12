{ ... }:
{
  requires = [ "storage-media.mount" "storage-scratch.mount" ];
  docker = {
    image = "mrcas/kapowarr";
    ports = [
      "5656"
    ];
    configVolume = "/app/db";
    volumes = [
      "/storage/media/Comics:/comics"
      "/storage/media/Comics.import:/import"
      # "/storage/scratch/torrent:/torrent"
      # "/storage/scratch/usenet:/usenet"
    ];
    extraOptions = [
      "--tmpfs=/app/temp_downloads"
    ];
  };
}
