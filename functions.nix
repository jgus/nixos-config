{ pkgs }:
let
  addresses = import ./addresses.nix;
in
{
  docker-services = { name, image, setup-script ? "", requires ? [] }:
  {
    systemd = {
      targets."${name}-requires" = {
        requires = requires;
        after = requires;
        requiredBy = [ "docker-${name}.service" ];
        before = [ "docker-${name}.service" ];
      };
      services =
        (if (setup-script == "") then {} else {
          "${name}-setup" = {
            path = [ pkgs.docker pkgs.rsync pkgs.zfs ];
            script = setup-script;
            serviceConfig = { Type = "oneshot"; };
            requires = [ "${name}-requires.target" ];
            after = [ "${name}-requires.target" ];
            requiredBy = [ "docker-${name}.service" ];
            before = [ "docker-${name}.service" ];
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
    };
  };

  scripts = {

  };
}