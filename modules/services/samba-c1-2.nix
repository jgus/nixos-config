with builtins;
{ lib, ... }:
{
  homelab.services.samba-c1-2 = {
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
          { name = "joyfulsong"; path = "/service/joyfulsong"; }
        ])) // {
          UID_joyfulsong = "33";
          ACCOUNT_joyfulsong = "joyfulsong";
        };
      volumes = [
        "${lib.homelab.storagePath "joyfulsong"}:/service/joyfulsong"
      ];
    };
  };
}
