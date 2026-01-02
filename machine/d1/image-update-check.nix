with builtins;
{ pkgs, lib, ... }:
let
  # Inline image extractor logic
  imagesDir = ./../../images;
  imageFiles = builtins.readDir imagesDir;

  nixFiles = builtins.filter
    (
      name:
      imageFiles.${name} == "regular"
      && lib.strings.hasSuffix ".nix" name
      && !(lib.strings.hasPrefix "." name)
    )
    (builtins.attrNames imageFiles);

  pullImagesInFile = name:
    [{
      pullImage = import (imagesDir + "/${name}");
      file = name;
    }];

  allPullImages = lib.concatMap pullImagesInFile nixFiles;

  latestDir = "/etc/nixos/images/latest";

  script = pkgs.writeShellScript "image-update-check" (''
    set -e
    
    echo "Checking Container images for updates..."

    tmpfile=$(${pkgs.coreutils}/bin/mktemp)
    exec 3<>"$tmpfile"
    rm "$tmpfile"

  ''
  +
  (builtins.concatStringsSep "\n" (map
    ({ pullImage, file }: ''
      echo "Checking ${pullImage.finalImageName}:${pullImage.finalImageTag} from ${file}..."
      if [ "$(skopeo inspect docker://${pullImage.finalImageName}:${pullImage.finalImageTag} --format '{{.Digest}}')" != "${pullImage.imageDigest}" ]
      then
        echo "Update available for ${pullImage.finalImageName}:${pullImage.finalImageTag} in ${file}; pulling..."
        echo "${pullImage.finalImageName}:${pullImage.finalImageTag} in ${file}" >&3
        ${pkgs.nix-prefetch-docker}/bin/nix-prefetch-docker --quiet --image-name ${pullImage.finalImageName} --image-tag ${pullImage.finalImageTag} > ${latestDir}/${file}
      fi
    '')
    allPullImages))
  +
  ''

    # If any outdated images found, send email notification
    if [ -s /dev/fd/3 ]; then
      {
        echo "subject: Container Image Updates Available"
        echo ""
        echo "The following container images have updates available:"
        echo ""
        cat /dev/fd/3
      } | ${pkgs.msmtp}/bin/msmtp "j@gustafson.me"
    else
      echo "All Container images are up to date."
    fi
  '');
in
{
  systemd.services = {
    image-update-check = {
      path = with pkgs; [
        bash
        coreutils
        msmtp
        nix-prefetch-docker
        skopeo
      ];
      script = ''
        ${script}
      '';
      serviceConfig = {
        Type = "oneshot";
      };
      startAt = "daily";
    };
  };
}

