{ config, pkgs, ... }:
let
  zwave-area = area: (
    {
      name = "zwave-${area}";
      docker = {
        pullImage =
          # nix-shell -p nix-prefetch-docker --run 'nix-prefetch-docker --quiet --image-name zwavejs/zwave-js-ui --image-tag latest'
          {
            imageName = "zwavejs/zwave-js-ui";
            imageDigest = "sha256:a7036e59a9d7916d1f92f2fa1e0b9f4a5ed317fc8bef38756368f7c865e0e95a";
            hash = "sha256-gBoEUfNkM7nCGZnCnzievuMeKRrNdDROiJcpgBShzX4=";
            finalImageName = "zwavejs/zwave-js-ui";
            finalImageTag = "latest";
          };
        environment = {
          TZ = config.time.timeZone;
        };
        ports = [
          "8091"
          "3000"
        ];
        configVolume = "/usr/src/app/store";
      };
    }
  );
in
map zwave-area [ "basement" "main" "north" "upstairs" ]
