let
  user = "josh";
  group = "media";
in
{ config, ... }:
let
  configuration = ''
    <?xml version="1.0" encoding="utf-8"?>
    <Config>
      <ApiKey>${config.sops.placeholder.prowlarr}</ApiKey>
      <AuthenticationMethod>Forms</AuthenticationMethod>
      <AuthenticationRequired>Enabled</AuthenticationRequired>
      <BindAddress>*</BindAddress>
      <Branch>master</Branch>
      <EnableSsl>False</EnableSsl>
      <InstanceName>Prowlarr</InstanceName>
      <LaunchBrowser>True</LaunchBrowser>
      <LogLevel>info</LogLevel>
      <Port>9696</Port>
      <SslCertPassword></SslCertPassword>
      <SslCertPath></SslCertPath>
      <SslPort>6969</SslPort>
      <UpdateMechanism>Docker</UpdateMechanism>
      <UrlBase></UrlBase>
    </Config>
  '';
in
{
  container = {
    pullImage = import ../images/prowlarr.nix;
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
      TZ = config.time.timeZone;
    };
    ports = [
      "9696"
    ];
    configVolume = "/config";
    volumes = [
      "${config.sops.templates."prowlarr/config.xml".path}:/config/config.xml:ro"
    ];
  };
  extraConfig = {
    sops = {
      secrets.prowlarr = { };
      templates."prowlarr/config.xml" = {
        content = configuration;
        owner = user;
      };
    };
  };
}
