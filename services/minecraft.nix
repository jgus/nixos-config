let
  user = "minecraft";
  group = "minecraft";
in
{ config, ... }:
{
  container = {
    pullImage = {
      imageName = "ghcr.io/jgus/minecraft-runner";
      imageDigest = "sha256:376991786225659f2e471c00b39c5fafa291f5d8c5ca81968ae03949fa95d8f0";
      hash = "sha256-i5puli98x56I6T/+CmRVMELFz7f31xHuwF4gHOWaf7U=";
      finalImageName = "ghcr.io/jgus/minecraft-runner";
      finalImageTag = "1.0.0-java21";
    };
    configVolume = "/home/minecraft/config";
    volumes = [
      "${../.secrets/minecraft}:/ssh-keys-inject"
    ];
    environment = {
      MINECRAFT_UID = toString config.users.users.${user}.uid;
      MINECRAFT_GID = toString config.users.groups.${group}.gid;
    };
  };
}
