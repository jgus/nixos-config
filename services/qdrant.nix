{ ... }:
{
  container = {
    pullImage = import ../images/qdrant.nix;
    configVolume = "/qdrant/storage";
    ports = [
      "6333"
    ];
    extraOptions = [
      "--read-only"
      "--tmpfs=/qdrant/snapshots:exec,mode=1777"
    ];
  };
}
