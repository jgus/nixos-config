with builtins;
{ config, lib, ... }:
{
  homelab.services.samba = {
    configStorage = false;
    container = {
      pullImage = import ../../images/samba.nix;
      readOnly = false;
      capabilities = {
        NET_ADMIN = true;
      };
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
        (listToAttrs (map
          (x:
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
          { name = "Temp"; path = "/storage/tmp"; }
          { name = "Brown"; path = "/storage/external/brown"; }
          { name = "Gustafson"; path = "/storage/external/Gustafson"; }
          { name = "www"; path = "/storage/service/www"; }
          { name = "dav"; path = "/storage/service/dav"; }
        ])) //
        (listToAttrs (map (g: { name = "GROUP_${g}"; value = toString config.users.groups.${g}.gid; }) (attrNames config.users.groups))) //
        (listToAttrs (map (u: { name = "UID_${u}"; value = toString config.users.users.${u}.uid; }) (attrNames config.users.users)));
      environmentFiles = [
        config.sops.secrets."samba".path
      ];
      volumes = [
        "/home:/home"
        "/storage:/storage"
      ];
    };
  };
  sops = lib.mkIf config.homelab.services.samba.enable {
    secrets."samba" = { };
  };
}
