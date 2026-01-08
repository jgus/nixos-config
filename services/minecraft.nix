let
  user = "minecraft";
  group = "minecraft";
in
{ config, pkgs, ... }:
let
  sshKeys = pkgs.runCommand "minecraft-ssh-merged" { } ''
    mkdir -p $out
    cp -r ${../.secrets/ssh/minecraft}/* $out/
    cp -r ${../pubkeys/minecraft}/* $out/
  '';
in
{
  container = {
    readOnly = false;
    pullImage = import ../images/minecraft-runner.nix;
    configVolume = "/home/minecraft/config";
    volumes = [
      "${sshKeys}:/ssh-keys-inject"
    ];
    environment = {
      MINECRAFT_UID = toString config.users.users.${user}.uid;
      MINECRAFT_GID = toString config.users.groups.${group}.gid;
    };
  };
}
