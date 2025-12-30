{ pkgs, lib, ... }:
let
  container = import ./container.nix { inherit pkgs lib; };
in
{
  users = {
    mutableUsers = false;

    groups = {
      users.gid = 100;
      plex.gid = 193;
      home-assistant.gid = 200;
      www.gid = 911;
      mosquitto.gid = 1883;
      minecraft.gid = 2000;
    };

    users = {
      root = {
        hashedPassword = "$y$j9T$kPkXW3Xo/TsdmLvo5eQE9/$z1/r/jzXvqtH/0xXO.pwtFYqlkt4LN7mnBEU1gjKNR2";
        openssh.authorizedKeys.keyFiles = [ ./pubkeys/josh-ed25519 ./pubkeys/josh-rsa ];
      };

      plex = {
        uid = 193;
        isSystemUser = true;
        group = "plex";
      };

      home-assistant = {
        uid = 200;
        isSystemUser = true;
        group = "home-assistant";
      };

      www = {
        uid = 911;
        isSystemUser = true;
        group = "www";
      };

      mosquitto = {
        uid = 1883;
        isSystemUser = true;
        group = "mosquitto";
      };

      gustafson = {
        uid = 1000;
        isNormalUser = true;
      };

      josh = {
        uid = 1001;
        isNormalUser = true;
        extraGroups = [ "wheel" "www" container.group "libvirtd" "davfs2" ];
        hashedPassword = "$y$j9T$ejqS3R1wFPz6VoSCPm6l31$e60wSoEFUtCCklzlwnCxdzre4vuNnmbJE8E/b6/tJ72";
        openssh.authorizedKeys.keyFiles = [ ./pubkeys/josh-ed25519 ./pubkeys/josh-rsa ];
      };

      nathaniel = {
        uid = 1023;
        isNormalUser = true;
      };

      minecraft = {
        uid = 2000;
        isSystemUser = true;
        group = "minecraft";
      };
    };
  };
}
