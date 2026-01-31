{ ... }:
{
  homelab.services.qdrant = {
    container = {
      pullImage = import ../../images/qdrant.nix;
      readOnly = true;
      configVolume = "/qdrant/storage";
      tmpFs = [
        "/qdrant/snapshots"
      ];
      ports = [
        "6333"
      ];
    };
  };
}
