let
  user = "josh";
  group = "media";
in
{ config, ... }:
let
  configuration = ''
    <?xml version="1.0" encoding="utf-8"?>
    <Config>
      <ApiKey>${config.sops.placeholder.radarr}</ApiKey>
      <AuthenticationMethod>External</AuthenticationMethod>
      <AuthenticationRequired>Enabled</AuthenticationRequired>
      <BindAddress>*</BindAddress>
      <Branch>master</Branch>
      <EnableSsl>False</EnableSsl>
      <InstanceName>Radarr</InstanceName>
      <LaunchBrowser>False</LaunchBrowser>
      <LogLevel>info</LogLevel>
      <Port>7878</Port>
      <SslCertPassword></SslCertPassword>
      <SslCertPath></SslCertPath>
      <SslPort>9898</SslPort>
      <UpdateMechanism>Docker</UpdateMechanism>
      <UrlBase></UrlBase>
    </Config>
  '';
in
{
  requires = [ "storage-media.mount" "storage-scratch.mount" ];
  container = {
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
        content = configuration;
        owner = user;
      };
    };
  };
}
