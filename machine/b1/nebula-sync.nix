with builtins;
{ config, pkgs, lib, ... }:
let
  pw = import ./../../.secrets/passwords.nix;
  addresses = import ./../../addresses.nix { inherit lib; };
  image = "ghcr.io/lovelaze/nebula-sync:latest";
in
{
  systemd.services = {
    nebula-sync = {
      path = with pkgs; [
        docker
      ];
      script = ''
        docker pull ${image}
        docker run --rm \
        --name nebula-sync \
        -e PRIMARY="http://pihole-1|${pw.pihole}" \
        -e REPLICAS="http://pihole-2|${pw.pihole},http://pihole-3|${pw.pihole}" \
        -e FULL_SYNC=false \
        -e SYNC_GRAVITY_GROUP=true \
        -e SYNC_GRAVITY_DOMAIN_LIST=true \
        -e SYNC_GRAVITY_DOMAIN_LIST_BY_GROUP=true \
        -e SYNC_GRAVITY_CLIENT=true \
        -e SYNC_GRAVITY_CLIENT_BY_GROUP=true \
        -e TZ="${config.time.timeZone}" \
        --add-host=pihole-1:${getAttr "pihole-1" addresses.nameToIp} \
        --add-host=pihole-2:${getAttr "pihole-2" addresses.nameToIp} \
        --add-host=pihole-3:${getAttr "pihole-3" addresses.nameToIp} \
        ${image}
      '';
      serviceConfig = {
        Type = "oneshot";
      };
      startAt = "hourly";
    };
  };
}
