with builtins;
{ config, pkgs, lib, ... }:
let
  addresses = import ./../../addresses.nix { inherit lib; };
  container = import ./../../container.nix { inherit pkgs lib; };
  image = "ghcr.io/lovelaze/nebula-sync:latest";
in
{
  systemd.services = {
    nebula-sync = {
      path = [ container.package ];
      script = ''
        export PW="$(cat ${config.sops.secrets.pihole.path})"
        ${container.executable} pull ${image}
        ${container.executable} run --rm \
        --name nebula-sync \
        -e PRIMARY="http://pihole-1|''${PW}" \
        -e REPLICAS="http://pihole-2|''${PW},http://pihole-3|''${PW}" \
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
  sops.secrets.pihole = { };
}
