with builtins;
args@{ config, pkgs, lib, ... }:
let
  # Import the image extractor
  allPullImages = import ./all-pull-images.nix args;
  script = pkgs.writeShellScript "image-update-check" (''
    set -e
    
    echo "Checking Docker images for updates..."

    tmpfile=$(${pkgs.coreutils}/bin/mktemp)
    exec 3<>"$tmpfile"
    rm "$tmpfile"

  ''
  +
  (builtins.concatStringsSep "\n" (map
    ({ pullImage, file }: ''
      echo "Checking ${pullImage.finalImageName}:${pullImage.finalImageTag} from ${file}..."
      CURRENT_SPEC_JSON_NORM=$(echo ${lib.escapeShellArg (builtins.toJSON pullImage)} | ${pkgs.jq}/bin/jq -S -c .)
      LATEST_SPEC_NIX=$(${pkgs.nix-prefetch-docker}/bin/nix-prefetch-docker --quiet --image-name ${pullImage.finalImageName} --image-tag ${pullImage.finalImageTag})
      LATEST_SPEC_JSON_NORM=$(${pkgs.nix}/bin/nix eval --json --expr "$LATEST_SPEC_NIX" | ${pkgs.jq}/bin/jq -S -c .)
      if [ "CURRENT_SPEC_JSON_NORM" != "LATEST_SPEC_JSON_NORM" ]
      then
        echo "Update available for ${pullImage.finalImageName}:${pullImage.finalImageTag}"
        echo "" >&3
        echo "${file}:" >&3
        echo "''${LATEST_SPEC_NIX}" >&3
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
        cat /dev/fd/3
      } | ${pkgs.msmtp}/bin/msmtp "j@gustafson.me"
    else
      echo "All Docker images are up to date."
    fi
  '');
in
{
  systemd.services = {
    image-update-check = {
      path = with pkgs; [
        nix
        msmtp
        bash
        coreutils
        jq
        nix-prefetch-docker
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

