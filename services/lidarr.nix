let
  user = "josh";
  group = "media";
in
{ config, ... }:
let
  configuration = ''
    <?xml version="1.0" encoding="utf-8"?>
    <Config>
      <ApiKey>${config.sops.placeholder.lidarr}</ApiKey>
      <AuthenticationMethod>External</AuthenticationMethod>
      <AuthenticationRequired>Enabled</AuthenticationRequired>
      <BindAddress>*</BindAddress>
      <Branch>master</Branch>
      <EnableSsl>False</EnableSsl>
      <InstanceName>Lidarr</InstanceName>
      <LaunchBrowser>False</LaunchBrowser>
      <LogLevel>info</LogLevel>
      <Port>8686</Port>
      <SslCertPassword></SslCertPassword>
      <SslCertPath></SslCertPath>
      <SslPort>6868</SslPort>
      <UpdateMechanism>Docker</UpdateMechanism>
      <UrlBase></UrlBase>
    </Config>
  '';
in
{
  # inherit user group;
  requires = [ "storage-media.mount" "storage-scratch.mount" ];
  container = {
    readOnly = false;
    pullImage = import ../images/lidarr.nix;
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
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
        content = configuration;
        owner = user;
      };
    };
  };
}
