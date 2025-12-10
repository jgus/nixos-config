with builtins;
let
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
  storagePath = name: "/service/${name}";
  storageBackupPath = name: "/storage/service/${name}";
  serviceDir = readDir ./services;
in
args@{ pkgs, lib, ... }:
let
  serviceNames = map (n: lib.strings.removeSuffix ".nix" n) (filter (n: serviceDir.${n} == "regular" && (lib.strings.hasSuffix ".nix" n) && !(lib.strings.hasPrefix "." n)) (attrNames serviceDir));
  homelabServiceStorage = name:
    let
      path = storagePath name;
      backupPath = storageBackupPath name;
    in
    {
      systemd.services = {
        "service-storage-${name}-setup" = {
          requires = (if machine.zfs then [ "zfs.target" ] else [ ]);
          after = (if machine.zfs then [ "zfs.target" ] else [ ]);
          path = [ pkgs.rsync ] ++ (if machine.zfs then [ pkgs.zfs ] else [ ]);
          script = ''
            if ! [ -d "${path}" ]
            then
              ${if machine.zfs then "zfs create r/service/${name}" else "mkdir -p ${path}"}
              if [ -d "${backupPath}" ]
              then
                rsync -arPW --delete ${backupPath}/ ${path}/
              fi
            fi
          '';
          serviceConfig = { Type = "oneshot"; };
        };
        "service-storage-${name}-backup" = {
          path = [ pkgs.rsync ];
          script = "(r=5; while ! rsync -arPW --delete ${path}/ ${backupPath}/; do ((--r))||exit; sleep 60; done)";
          serviceConfig = { Type = "exec"; };
          startAt = "hourly";
        };
      };
    };
  homelabService =
    { name
    , user ? "root"
    , group ? "root"
    , configStorage ? true
    , extraStorage ? [ ]
    , requires ? [ ]
    , autoStart ? true
    , docker ? { }
    , systemd ? { }
    , extraConfig ? { }
    ,
    }: { config, ... }:
    let
      args = {
        inherit requires;
      };
      uid = toString config.users.users.${user}.uid;
      gid = toString config.users.groups.${group}.gid;
      storageNames = (extraStorage ++ (if configStorage then [ name ] else [ ]));
      dockerOptions = addresses.dockerOptions name;
      isDocker = docker ? image;
      dockerConfig = {
        imports = [ ./docker.nix extraConfig ] ++ (map (s: homelabServiceStorage s) storageNames);

        systemd = {
          targets."${name}-requires" = rec {
            requires = (map (s: "service-storage-${s}-setup.service") storageNames);
            after = requires;
            requiredBy = [ "${name}.service" ];
            before = requiredBy;
          };
          services = {
            "docker-${name}" = {
              aliases = [ "${name}.service" ];
              serviceConfig.Restart = pkgs.lib.mkForce "no";
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
        virtualisation.oci-containers.containers.${name} = {
          image = docker.image;
          autoStart = autoStart;
          user = "${uid}:${gid}";
          volumes =
            (if (docker ? volumes) then (if (isFunction docker.volumes) then (docker.volumes storagePath) else docker.volumes) else [ ]) ++
              (if configStorage then [ "${storagePath name}:${docker.configVolume}" ] else [ ]);
          extraOptions = (if (docker ? extraOptions) then docker.extraOptions else [ ])
            ++ dockerOptions;
          entrypoint = (if (docker ? entrypoint) then docker.entrypoint else null);
          cmd = (if (docker ? entrypointOptions) then docker.entrypointOptions else [ ]);
        }
        // (if (docker ? imageFile) then { imageFile = docker.imageFile; } else { })
        // (if (docker ? dependsOn) then { dependsOn = docker.dependsOn; } else { })
        // (if (docker ? environment) then { environment = docker.environment; } else { })
        // (if (docker ? environmentFiles) then { environmentFiles = docker.environmentFiles; } else { })
        // (if (docker ? ports) then { ports = docker.ports; } else { })
        ;
      };
      systemdConfig = {
        imports = [ extraConfig ] ++ (map (s: homelabServiceStorage s) storageNames);

        systemd = {
          targets."${name}-requires" = rec {
            requires = (map (s: "service-storage-${s}-setup.service") storageNames);
            after = requires;
            requiredBy = [ "${name}.service" ];
            before = requiredBy;
          };
          services = {
            "${name}" = rec {
              enable = true;
              description = name;
              wantedBy = (if autoStart then [ "multi-user.target" ] else [ ]);
              requires = args.requires ++ [ "network-online.target" "${name}-requires.target" ];
              after = requires;
              path = (if (systemd ? path) then systemd.path else [ ]);
              script = (if (systemd ? script) then (systemd.script { inherit name uid gid storagePath dockerOptions; }) else "");
              postStop = "systemctl restart ${name}-backup";
            };
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
      };
      serviceConfig = if isDocker then dockerConfig else systemdConfig;
    in
    if (machine.hostName == addresses.records.${name}.host) then serviceConfig else { };
  importService = n:
    let
      i = (import ./services/${n}.nix) args;
    in
    if (isList i) then (map (f: homelabService f) i) else (homelabService ({ name = n; } // i));
in
{
  imports = lib.lists.flatten (map importService serviceNames);
}
