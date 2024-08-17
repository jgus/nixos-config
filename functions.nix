{ pkgs }:
let
  addresses = import ./addresses.nix;
in
{
  docker-services = { name, image, setup-script ? "", backup-script ? "" }:
  (if (setup-script == "") then {} else {
    "${name}-setup" = {
      path = [ pkgs.docker pkgs.rsync pkgs.zfs ];
      script = setup-script;
      serviceConfig = { Type = "oneshot"; };
      requiredBy = [ "docker-${name}.service" ];
      before = [ "docker-${name}.service" ];
    };
  }) // (if (backup-script == "") then {} else {
    "${name}-backup" = {
      path = [ pkgs.rsync pkgs.zfs ];
      script = backup-script;
      serviceConfig = { Type = "exec"; };
      startAt = "hourly";
    };
    "${name}-shutdown-backup" = {
      path = [ pkgs.docker ];
      script = ''
        while ! docker container ls --format {{.Names}} | grep ^${name}$; do sleep 1; done
        docker container wait ${name}
        systemctl restart ${name}-backup
      '';
      serviceConfig = { Type = "exec"; };
      wantedBy = [ "docker-${name}.service" ];
      after = [ "docker-${name}.service" ];
    };
  }) // {
    "${name}-update" = {
      path = [ pkgs.docker ];
      script = ''
        if docker pull ${image} | grep "Status: Downloaded"
        then
          systemctl restart docker-${name}
        fi
      '';
      serviceConfig = { Type = "exec"; };
      startAt = "hourly";
    };
  };
  scripts = {

  };
}