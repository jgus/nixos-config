{ ... }:
{
  configStorage = false;
  container = {
    pullImage = import ../images/qdrant.nix;
    configStorage = "/qdrant/storage";
    ports = [
      "6333"
    ];
  };
}
