let
  user = "josh";
  group = "plex";
in
{ config, ... }:
{
  requires = [ "storage-scratch.mount" ];
  container = {
    pullImage = {
      imageName = "lscr.io/linuxserver/sabnzbd";
      imageDigest = "sha256:ed10a7e9fc019aded46f1591f236e9be6d75c99e7017b897b502667cd65afc4c";
      hash = "sha256-KGFduHqgjnSdPNtzeyzCQn87K0dujvObFnojoR5QB74=";
      finalImageName = "lscr.io/linuxserver/sabnzbd";
      finalImageTag = "latest";
    };
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      TZ = config.time.timeZone;
    };
    ports = [
      "8080"
    ];
    configVolume = "/config";
    volumes = [
      "/storage/scratch/usenet:/config/Downloads"
    ];
  };
}
