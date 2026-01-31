let
  user = "josh";
  group = "media";
in
{ ... }:
{
  homelab.services.komga = {
    inherit user group;
    requires = [ "storage-media.mount" ];
    container = {
      pullImage = import ../../images/komga.nix;
      environment = {
        SERVER_PORT = "25600";
      };
      configVolume = "/config";
      volumes = [
        "/storage/media/Comics:/data"
      ];
      ports = [
        "25600"
      ];
    };
  };
}
