{ ... }:
{
  container = {
    pullImage = import ../images/qdrant.nix;
    configVolume = "/qdrant/storage";
    ports = [
      "6333"
    ];
    readOnly = true;
    tmpFs = [
      "/qdrant/snapshots"
    ];
  };
}
