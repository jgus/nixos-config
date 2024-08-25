{ pkgs }:
with builtins;
let
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
  storagePath = name: "/service/${name}";
  storageNasPath = name: "/nas/service/${name}";

  homelabServiceStorage = name: 
  let
    path = storagePath name;
    nasPath = storageNasPath name;
  in
  {
    systemd.services = {
      "service-storage-${name}-setup" = {
        path = [ pkgs.rsync ] ++ (if machine.zfs then [ pkgs.zfs ] else []);
        script = ''
          if ! [ -d ${path} ]
          then
            ${if machine.zfs then "zfs create r/service/${name}" else "mkdir -p ${path}"}
            rsync -arPW --delete ${nasPath}/ ${path}/
          fi
        '';
        serviceConfig = { Type = "oneshot"; };
      };
      "service-storage-${name}-backup" = {
        path = [ pkgs.rsync ];
        script = "rsync -arPW --delete ${path}/ ${nasPath}/";
        serviceConfig = { Type = "exec"; };
        startAt = "hourly";
      };
    };
  };
in
{
  homelabService = {
      name,
      user ? "root",
      group ? "root",
      configStorage ? true,
      extraStorage ? [],
      requires ? [],
      docker ? {},
      systemd ? {},
      extraConfig ? {},
    }: { config, ... }:
    let
      args = {
        inherit requires;
      };
      uid = toString config.users.users.${user}.uid;
      gid = toString config.users.groups.${group}.gid;
      storageNames = (extraStorage ++ (if configStorage then [ name ] else []));
      dockerOptions = addresses.dockerOptions name;
    in
    if (machine.hostName != addresses.records.${name}.host) then {} else
    {
      imports =
        (if (docker ? image) then [ ./docker.nix ] else []) ++
        (map (s: homelabServiceStorage s) storageNames) ++ 
        [ extraConfig ];

      systemd = {
        targets."${name}-requires" = rec {
          requires = (map (s: "service-storage-${s}-setup.service") storageNames);
          after = requires;
          requiredBy = [ "${name}.service" ];
          before = requiredBy;
        };
        services = {
        } // (if (docker ? image) then {
          "docker-${name}" = {
            aliases = [ "${name}.service" ];
          };
          "${name}-onstop" = rec {
            path = [ pkgs.docker pkgs.rsync ];
            script = ''
              while ! docker container ls --format {{.Names}} | grep ^${name}$; do sleep 1; done
              docker container wait ${name}
              systemctl restart ${name}-backup
            '';
            serviceConfig = { Type = "oneshot"; };
            requiredBy = [ "${name}.service" ];
            after = requiredBy;
          };
          "${name}-update" = {
            path = [ pkgs.docker ];
            script = ''
              if docker pull ${docker.image} | grep "Status: Downloaded"
              then
                systemctl restart ${name}
              fi
            '';
            serviceConfig = { Type = "exec"; };
            startAt = "hourly";
          };
        } else {
          "${name}" = rec {
            enable = true;
            description = name;
            wantedBy = [ "multi-user.target" ];
            requires = args.requires ++ [ "network-online.target" "${name}-requires.target" ];
            after = requires;
            path = (if (systemd ? path) then systemd.path else []);
            script = (if (systemd ? script) then (systemd.script { inherit name uid gid storagePath dockerOptions; }) else "");
            postStop = "systemctl restart ${name}-backup";
          };
        }) // {
          "${name}-backup" = {
            script = ''
              ${concatStringsSep "\n" (map (s: "systemctl restart service-storage-${s}-backup") storageNames)}
              true
            '';
            serviceConfig = { Type = "exec"; };
            startAt = "hourly";
          };
        };
      };
    }
    //
    (if (docker ? image) then {
      virtualisation.oci-containers.containers.${name} = {
        image = docker.image;
        autoStart = true;
        user = "${uid}:${gid}";
        volumes =
          (if (docker ? volumes) then (if (isFunction docker.volumes) then (docker.volumes storagePath) else docker.volumes) else []) ++
          (if configStorage then [ "${storagePath name}:${docker.configVolume}" ] else []);
        extraOptions = (if (docker ? extraOptions) then docker.extraOptions else [])
          ++ dockerOptions;
      }
      // (if (docker ? dependsOn) then { dependsOn = docker.dependsOn; } else {})
      // (if (docker ? environment) then { environment = docker.environment; } else {})
      // (if (docker ? environmentFiles) then { environmentFiles = docker.environmentFiles; } else {})
      // (if (docker ? ports) then { ports = docker.ports; } else {})
      ;
    } else {});
}