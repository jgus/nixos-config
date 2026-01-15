let
  user = "josh";
  group = "media";
in
{ config, myLib, ... }:
let
  configuration = {
    Config = {
      ApiKey = config.sops.placeholder.sonarr;
      AuthenticationMethod = "External";
      AuthenticationRequired = "Enabled";
      BindAddress = "*";
      Branch = "main";
      EnableSsl = "False";
      InstanceName = "Sonarr";
      LaunchBrowser = "False";
      LogLevel = "info";
      Port = "8989";
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
    pullImage = import ../images/sonarr.nix;
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      TZ = config.time.timeZone;
    };
    ports = [
      "8989"
    ];
    configVolume = "/config";
    volumes = [
      "${config.sops.templates."sonarr/config.xml".path}:/config/config.xml:ro"
      "/storage/scratch/torrent:/torrent"
      "/storage/scratch/usenet:/usenet"
      "/storage/media:/media"
    ];
  };
  extraConfig = {
    sops = {
      secrets.sonarr = { };
      templates."sonarr/config.xml" = {
        content = builtins.readFile (myLib.prettyXml configuration);
        owner = user;
      };
    };
  };
}
