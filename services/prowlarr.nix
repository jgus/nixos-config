let
  user = "josh";
  group = "plex";
in
{ config, ... }:
{
  container = {
    pullImage = {
      imageName = "lscr.io/linuxserver/prowlarr";
      imageDigest = "sha256:67a8aaedcfd6989f3030b937a6a07007310b1dfc7ee8df16d2cbfa48d1c1158c";
      hash = "sha256-sUFMy1onFMWo/S1Ms81D8mJFXQEtxZmRcfgM6jwFrVQ=";
      finalImageName = "lscr.io/linuxserver/prowlarr";
      finalImageTag = "latest";
    };
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      TZ = config.time.timeZone;
    };
    ports = [
      "9696"
    ];
    configVolume = "/config";
  };
}
