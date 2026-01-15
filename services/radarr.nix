let
  user = "josh";
  group = "media";
in
{ config, myLib, ... }:
let
  configuration = {
    Config = {
      ApiKey = config.sops.placeholder.radarr;
      AuthenticationMethod = "External";
      AuthenticationRequired = "Enabled";
      BindAddress = "*";
      Branch = "master";
      EnableSsl = "False";
      InstanceName = "Radarr";
      LaunchBrowser = "False";
      LogLevel = "info";
      Port = "7878";
      SslCertPassword = "";
      SslCertPath = "";
      SslPort = "9898";
      UpdateMechanism = "Docker";
      UrlBase = "";
    };
  };
in
{
  requires = [ "storage-media.mount" "storage-scratch.mount" ];
  container = {
    readOnly = false;
    pullImage = import ../images/radarr.nix;
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      TZ = config.time.timeZone;
    };
    ports = [
      "7878"
    ];
    configVolume = "/config";
    volumes = [
      "${config.sops.templates."radarr/config.xml".path}:/config/config.xml:ro"
      "/storage/scratch/torrent:/torrent"
      "/storage/scratch/usenet:/usenet"
      "/storage/media:/media"
    ];
  };
  extraConfig = {
    sops = {
      secrets.radarr = { };
      templates."radarr/config.xml" = {
        content = builtins.readFile (myLib.prettyXml configuration);
        owner = user;
      };
    };
  };
}
