{ ... }:
{
  requires = [ "storage-media.mount" "storage-scratch.mount" ];
  docker = {
    pullImage =
      # nix-shell -p nix-prefetch-docker --run 'nix-prefetch-docker --quiet --image-name mrcas/kapowarr --image-tag latest'
      {
        imageName = "mrcas/kapowarr";
        imageDigest = "sha256:484f7decc7cc7af77542aba5516f48a62b17f72116ac7309d1709b72bb7d0ba2";
        hash = "sha256-ksnZ0tSXZ2VPnYtwgrIRSixnuvuEX5fRxYyFyyNsnCU=";
        finalImageName = "mrcas/kapowarr";
        finalImageTag = "latest";
      };
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
