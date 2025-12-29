let
  user = "josh";
  group = "plex";
in
{ config, ... }:
{
  requires = [ "storage-scratch.mount" ];
  container = {
    pullImage = {
      imageName = "lscr.io/linuxserver/qbittorrent";
      imageDigest = "sha256:1497b6e047ad47b738f94739219f0e5c5b2ad7a5953b7cf0050f2fedddd8c601";
      hash = "sha256-PUapqpJ6rZjWmmvKzJS2vYNC0Ew0UdM+Y1Z8Epk3V3o=";
      finalImageName = "lscr.io/linuxserver/qbittorrent";
      finalImageTag = "latest";
    };
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      TZ = config.time.timeZone;
      WEBUI_PORT = "80";
      TORRENTING_PORT = "6881";
    };
    ports = [
      "80"
      "6881"
      "6881/udp"
    ];
    configVolume = "/config";
    volumes = [
      "/storage/scratch/torrent:/torrent"
    ];
  };
}
