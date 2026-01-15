let
  user = "josh";
  group = "media";
in
{ config, myLib, ... }:
let
  configuration = {
    Config = {
      ApiKey = config.sops.placeholder.lidarr;
      AuthenticationMethod = "External";
      AuthenticationRequired = "Enabled";
      BindAddress = "*";
      Branch = "master";
      EnableSsl = "False";
      InstanceName = "Lidarr";
      LaunchBrowser = "False";
      LogLevel = "info";
      Port = "8686";
      SslCertPassword = "";
      SslCertPath = "";
      SslPort = "6868";
      UpdateMechanism = "Docker";
      UrlBase = "";
    };
  };
in
{
  requires = [ "storage-media.mount" "storage-scratch.mount" ];
  container = {
    readOnly = false;
    pullImage = import ../images/lidarr.nix;
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      TZ = config.time.timeZone;
    };
    ports = [
      "8686"
    ];
    configVolume = "/config";
    volumes = [
      "${config.sops.templates."lidarr/config.xml".path}:/config/config.xml:ro"
      "/storage/scratch/torrent:/torrent"
      "/storage/scratch/usenet:/usenet"
      "/storage/media:/media"
    ];
  };
  extraConfig = {
    sops = {
      secrets.lidarr = { };
      templates."lidarr/config.xml" = {
        content = builtins.readFile (myLib.prettyXml configuration);
        owner = user;
      };
    };
  };
}
