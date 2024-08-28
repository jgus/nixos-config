{ config, ... }:
with builtins;
let
  pw = import ./../.secrets/passwords.nix;
in
{
  configStorage = false;
  docker = {
    image = "ghcr.io/servercontainers/samba";
    environment =
      {
        SAMBA_GLOBAL_STANZA = concatStringsSep ";" [
          "fruit:metadata = stream"
          "fruit:veto_appledouble = yes"
          "fruit:nfs_aces = no"
          "fruit:wipe_intentionally_left_blank_rfork = yes"
          "fruit:delete_empty_adfiles = yes"
        ];
        SAMBA_VOLUME_CONFIG_TimeMachine = concatStringsSep ";" [
          "[TimeMachine]"
          "path = /storage/backup/timemachine"
          "browseable = yes"
          "read only = no"
          "fruit:time machine = yes"
          "fruit:time machine max size = 1T"
        ];
      } //
      (listToAttrs (map (x:
        {
          name = "SAMBA_VOLUME_CONFIG_${x.name}";
          value = concatStringsSep ";" [
            "[${x.name}]"
            "path = ${x.path}"
            "browseable = yes"
            "read only = no"
          ];
        }) [
        { name = "home"; path = "/home/%U"; }
        { name = "Media"; path = "/storage/media"; }
        { name = "Backup"; path = "/storage/backup"; }
        { name = "BackupHA"; path = "/storage/backup/Home Assistant"; }
        { name = "Scratch"; path = "/storage/scratch"; }
        { name = "Scan"; path = "/storage/scratch/scan"; }
        { name = "Photos"; path = "/storage/photos"; }
        { name = "Projects"; path = "/storage/projects"; }
        { name = "Software"; path = "/storage/software"; }
        { name = "Storage"; path = "/home/josh/Storage"; }
        { name = "Temp"; path = "/storage/tmp"; }
        { name = "Brown"; path = "/storage/external/brown"; }
        { name = "Gustafson"; path = "/storage/external/Gustafson"; }
        { name = "www"; path = "/var/lib/www"; }
        { name = "dav"; path = "/var/lib/dav"; }
      ])) //
      (listToAttrs (map (g: { name = "GROUP_${g}"; value = toString config.users.groups.${g}.gid; }) (attrNames config.users.groups))) //
      (listToAttrs (map (u: { name = "UID_${u}"; value = toString config.users.users.${u}.uid; }) (attrNames config.users.users))) //
      (listToAttrs (map (u: { name = "ACCOUNT_${u}"; value = pw.samba.${u}; }) (attrNames pw.samba)));
    volumes = [
      "/home:/home"
      "/storage:/storage"
    ];
    extraOptions = [
      "--cap-add=NET_ADMIN"
    ];
  };
  extraConfig = {
    fileSystems."/storage/tmp" = { device = "tmpfs"; fsType = "tmpfs"; };
  };
}
