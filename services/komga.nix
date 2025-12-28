let
  user = "josh";
  group = "plex";
in
{ config, ... }:
{
  inherit user group;
  requires = [ "storage-media.mount" ];
  docker = {
    pullImage =
      # nix-shell -p nix-prefetch-docker --run 'nix-prefetch-docker --quiet --image-name gotson/komga --image-tag latest'
      {
        imageName = "gotson/komga";
        imageDigest = "sha256:09129eae6eff50337f039bd6e99d995126cb03226950c80e9864cbc05f10a661";
        hash = "sha256-1fQcVatovaPDU1PSl7jMoryFxwFI9sjGSvrzsdgcY1E=";
        finalImageName = "gotson/komga";
        finalImageTag = "latest";
      };
    environment = {
      TZ = config.time.timeZone;
      SERVER_PORT = "25600";
    };
    ports = [
      "25600"
    ];
    configVolume = "/config";
    volumes = [
      "/storage/media/Comics:/data"
    ];
  };
}
