let
  user = "josh";
  group = "users";
in
{ config, ... }:
{
  container = {
    readOnly = false;
    pullImage = import ../images/code-server.nix;
    configVolume = "/config";
    ports = [
      "8443"
    ];
    environment = {
      PUID = toString config.users.users.${user}.uid;
      PGID = toString config.users.groups.${group}.gid;
    };
    environmentFiles = [
      config.sops.secrets."code/env".path
    ];
    volumes = storagePath: [
      "${storagePath "code-server"}/nix:/nix"
    ];
  };
  extraConfig = {
    sops.secrets."code/env" = { };
  };
}
