with builtins;
{ config, lib, ... }:
let
  image = "ghcr.io/lovelaze/nebula-sync:latest";
in
{
  systemd.services = {
    nebula-sync = {
      path = [ config.homelab.container.package ];
      script = ''
        export PW="$(cat ${config.sops.secrets.pihole.path})"
        ${config.homelab.container.executable} pull ${image}
        ${config.homelab.container.executable} run --rm \
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
        --add-host=pihole-1:${getAttr "pihole-1" lib.homelab.nameToIp} \
        --add-host=pihole-2:${getAttr "pihole-2" lib.homelab.nameToIp} \
        --add-host=pihole-3:${getAttr "pihole-3" lib.homelab.nameToIp} \
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
