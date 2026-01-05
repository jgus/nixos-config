{ ... }:
{
  requires = [ "storage-media.mount" "storage-scratch.mount" ];
  container = {
    readOnly = false;
    pullImage = import ../images/kapowarr.nix;
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
