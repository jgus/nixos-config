let
  user = "josh";
  group = "media";
in
{ config, lib, ... }:
let
  configuration = ''
    <?xml version="1.0" encoding="utf-8"?>
    <Config>
      <ApiKey>${config.sops.placeholder.sonarr}</ApiKey>
      <AuthenticationMethod>External</AuthenticationMethod>
      <AuthenticationRequired>Enabled</AuthenticationRequired>
      <BindAddress>*</BindAddress>
      <Branch>main</Branch>
      <EnableSsl>False</EnableSsl>
      <InstanceName>Sonarr</InstanceName>
      <LaunchBrowser>False</LaunchBrowser>
      <LogLevel>info</LogLevel>
      <Port>8989</Port>
      <SslCertPassword></SslCertPassword>
      <SslCertPath></SslCertPath>
      <SslPort>9898</SslPort>
      <UpdateMechanism>Docker</UpdateMechanism>
      <UrlBase></UrlBase>
    </Config>
  '';
in
{
  homelab.services.sonarr = {
    requires = [ "storage-media.mount" "storage-scratch.mount" ];
    container = {
      pullImage = import ../../images/sonarr.nix;
      readOnly = false;
      environment = {
        PUID = toString config.users.users.${user}.uid;
        PGID = toString config.users.groups.${group}.gid;
      };
      configVolume = "/config";
      volumes = [
        "${config.sops.templates."sonarr/config.xml".path}:/config/config.xml:ro"
        "/storage/scratch/torrent:/torrent"
        "/storage/scratch/usenet:/usenet"
        "/storage/media:/media"
      ];
      ports = [
        "8989"
      ];
    };
  };
  sops = lib.mkIf config.homelab.services.sonarr.enable {
    secrets.sonarr = { };
    templates."sonarr/config.xml" = {
      content = configuration;
      owner = user;
    };
  };
}
