with builtins;
{ pkgs, ... }:
{
  configStorage = false;
  docker = {
    image = "ghcr.io/servercontainers/samba";
    imageFile = pkgs.dockerTools.pullImage
      # nix-shell -p nix-prefetch-docker --run 'nix-prefetch-docker --quiet --image-name ghcr.io/servercontainers/samba --image-tag latest'
      {
        imageName = "ghcr.io/servercontainers/samba";
        imageDigest = "sha256:14666eb79560feaf3f15b0bec335d1653403b047e093f1a0fef30f8039ab7";
        hash = "sha256-eqT+ayCV9q1QKSara1EICsXh0mzc90yhrEeZjdG+brs=";
        finalImageName = "ghcr.io/servercontainers/samba";
        finalImageTag = "latest";
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
      "/service/joyfulsong:/service/joyfulsong"
    ];
    extraOptions = [
      "--cap-add=NET_ADMIN"
    ];
  };
}
