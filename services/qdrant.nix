{ ... }:
{
  container = {
    pullImage = import ../images/qdrant.nix;
    configVolume = "/qdrant/storage";
    ports = [
      "6333"
    ];
    readOnly = true;
    extraOptions = [
      "--tmpfs=/qdrant/snapshots:exec,mode=1777"
    ];
  };
}
