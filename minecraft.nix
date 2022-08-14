{ pkgs, lib, ... }:

{
  imports = [ ./docker.nix ];

  users = {
    groups.minecraft = { gid = 996; };
    users.minecraft = {
      uid = 998;
      isSystemUser = true;
      group = "minecraft";
    };
  };

  environment.etc = lib.attrsets.mapAttrs' (name: value: lib.attrsets.nameValuePair ("minecraft/docker/${name}") { source = ./minecraft/docker/${name}; mode = "0444"; }) (builtins.readDir ./minecraft/docker);

  system.activationScripts = {
    minecraftSetup.text = ''
      ${pkgs.docker}/bin/docker build \
        --build-arg uid=$(id -u minecraft) \
        --build-arg gid=$(id -g minecraft) \
        --build-arg java_ver=17 \
        -t minecraft \
        /etc/minecraft/docker

      ${pkgs.zfs}/bin/zfs list rpool/varlib/minecraft >/dev/null 2>&1 || ( ${pkgs.zfs}/bin/zfs create rpool/varlib/minecraft && chown minecraft:minecraft /var/lib/minecraft )
    '';
  };

  # systemd = {
  #   services = {
  #     landing = {
  #       enable = true;
  #       description = "Landing";
  #       wantedBy = [ "multi-user.target" ];
  #       requires = [ "network-online.target" ];
  #       path = [ pkgs.docker pkgs.rsync ];
  #       script = ''
  #         rsync -arPL /etc/landing /tmp/
  #         rsync -arPL /etc/nixos/.secrets/landing /tmp/
  #         chmod a+x /tmp/landing/docker/entrypoint.sh
  #         docker build -t ssh /tmp/landing/docker
  #         /bin/sh -c "docker run --rm --name landing \
  #           -p 22022:22/tcp \
  #           -e AUTHORIZED_KEYS='$(cat /root/.ssh/id_rsa-backup.pub)' \
  #           -v /tmp/landing/etc/ssh:/etc/ssh \
  #           ssh"
  #         '';
  #       unitConfig = {
  #         StartLimitIntervalSec = 0;
  #       };
  #       serviceConfig = {
  #         Restart = "always";
  #         RestartSec = 10;
  #       };
  #     };
  #   };
  # };
}
