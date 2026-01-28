let
  user = "josh";
  group = "users";
in
{ config, lib, ... }:
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
      USER = "abc";
    };
    environmentFiles = [
      config.sops.secrets."code/env".path
    ];
    volumes = [
      "${config.sops.secrets."josh/ssh/id_ed25519".path}:/config/.ssh/id_ed25519:ro"
      "${../pubkeys/josh/id_ed25519}:/config/.ssh/id_ed25519.pub:ro"
      "${config.sops.secrets."josh/ssh/id_rsa".path}:/config/.ssh/id_rsa:ro"
      "${../pubkeys/josh/id_rsa}:/config/.ssh/id_rsa.pub:ro"
      "${lib.homelab.storagePath "code-server"}/nix:/nix"
    ];
    tmpFs = [
      "/tmp"
      "/config/tmp:mode=0777"
    ];
  };
  extraConfig = {
    sops.secrets."code/env" = { };
    sops.secrets."josh/ssh/id_ed25519" = {
      format = "binary";
      sopsFile = ../secrets/josh/ssh/id_ed25519;
      owner = user;
      group = group;
    };
    sops.secrets."josh/ssh/id_rsa" = {
      format = "binary";
      sopsFile = ../secrets/josh/ssh/id_rsa;
      owner = user;
      group = group;
    };
  };
}
