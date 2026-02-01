{ ... }:
{
  homelab.services.kapowarr = {
    requires = [ "storage-media.mount" "storage-scratch.mount" ];
    container = {
      pullImage = import ../../images/kapowarr.nix;
      readOnly = false;
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
      tmpFs = [
        "/app/temp_downloads"
      ];
    };
  };
}
