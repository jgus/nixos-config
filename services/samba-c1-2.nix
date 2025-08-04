with builtins;
let
  pw = import ./../.secrets/passwords.nix;
in
{ config, ... }:
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
      "/service/joyfulsong:/service/joyfulsong"
    ];
    extraOptions = [
      "--cap-add=NET_ADMIN"
    ];
  };
}
