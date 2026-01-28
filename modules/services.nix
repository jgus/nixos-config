with builtins;
args@{ lib, machine, pkgs, ... }:
let
  homelabServiceStorage = serviceName:
    let
      path = lib.homelab.storagePath serviceName;
      backupPath = lib.homelab.storageBackupPath serviceName;
      zfsDeps = lib.optional machine.zfs "zfs.target";
    in
    {
      systemd.services = {
        "service-storage-${serviceName}-setup" = {
          requires = zfsDeps;
          after = zfsDeps;
          path = [ pkgs.rsync ] ++ lib.optional machine.zfs pkgs.zfs;
          script = ''
            if ! [ -d "${path}" ]
            then
              ${if machine.zfs then "zfs create r${path}" else "mkdir -p ${path}"}
              if [ -d "${backupPath}" ]
              then
                rsync -arPW --delete ${backupPath}/ ${path}/
              fi
            fi
          '';
          serviceConfig = { Type = "oneshot"; };
        };
        "service-storage-${serviceName}-backup" = {
          path = [ pkgs.rsync ];
          script = "(r=5; while ! rsync -arPW --delete ${path}/ ${backupPath}/; do ((--r))||exit; sleep 60; done)";
          serviceConfig = { Type = "exec"; };
          startAt = "hourly";
        };
      };
    };
  homelabService =
    { serviceName
    , user ? "root"
    , group ? "root"
    , configStorage ? true
    , extraStorage ? [ ]
    , requires ? [ ]
    , autoStart ? true
    , container ? { }
    , systemd ? { }
    , extraConfig ? { }
    ,
    }@args: { config, ... }:
    let
      serviceRequires = requires;
      uid = toString config.users.users.${user}.uid;
      gid = toString config.users.groups.${group}.gid;
      storageNames = extraStorage ++ lib.optional configStorage serviceName;
      argsContainer = args.container or { };
      container = argsContainer // (if argsContainer ? pullImage then {
        image = "${argsContainer.pullImage.finalImageName}:${argsContainer.pullImage.finalImageTag}";
        imageFile = lib.homelab.pullImage argsContainer.pullImage;
      } else { });
      containerOptions = lib.homelab.containerOptions serviceName;
      isContainer = container ? image;

      # Shared service components used by both container and systemd configs
      requiresTarget = rec {
        requires = map (s: "service-storage-${s}-setup.service") storageNames;
        after = requires;
        requiredBy = [ "${serviceName}.service" ];
        before = requiredBy;
      };

      backupService = {
        script = ''
          ${concatStringsSep "\n" (map (s: "systemctl restart service-storage-${s}-backup") storageNames)}
          true
        '';
        serviceConfig = { Type = "exec"; };
        startAt = "hourly";
      };

      containerConfig = {
        imports = [
          extraConfig
        ] ++ map homelabServiceStorage storageNames;

        homelab.container.enable = true;

        systemd = {
          targets."${serviceName}-requires" = requiresTarget;
          services = {
            "${serviceName}" = {
              aliases = [ "homelab-${serviceName}.service" ];
              serviceConfig.Restart = pkgs.lib.mkForce "no";
              postStop = "systemctl restart ${serviceName}-backup";
            };
            "${serviceName}-update" = lib.mkIf (!(container ? imageFile || container ? imageStream || container ? pullImage)) {
              path = [ containerConfig.package ];
              script = ''
                if ${containerConfig.executable} pull ${container.image} | grep "Status: Downloaded"
                then
                  systemctl restart ${serviceName}
                fi
              '';
              serviceConfig = { Type = "exec"; };
              startAt = "hourly";
            };
            "${serviceName}-backup" = backupService;
          };
        };
        virtualisation.oci-containers.containers.${serviceName} = {
          inherit serviceName;
          autoStart = autoStart;
          user = "${uid}:${gid}";
          volumes =
            [ "${pkgs.tzdata}/share/zoneinfo:/etc/zoneinfo:ro" ]
              ++ (container.volumes or [ ])
              ++ lib.optional configStorage "${lib.homelab.storagePath serviceName}:${container.configVolume}";
          extraOptions =
            (container.extraOptions or [ ])
              ++ containerOptions
              ++ (lib.optional (container.readOnly or true) "--read-only")
              ++ (map (value: "--tmpfs=${value}") (container.tmpFs or [ ]))
              ++ [ "--health-interval=disable" ]
          ;
          cmd = container.entrypointOptions or [ ];
          environment = {
            TZ = config.time.timeZone;
            TZDIR = "/etc/zoneinfo";
          } // (container.environment or { });
        }
        // lib.pipe
          [
            "autoRemoveOnStop"
            "capabilities"
            "dependsOn"
            "devices"
            "entrypoint"
            "environmentFiles"
            "hostname"
            "image"
            "imageFile"
            "imageStream"
            "labels"
            "log-driver"
            "login"
            "networks"
            "podman"
            "ports"
            "preRunExtraOptions"
            "privileged"
            "pull"
            "workdir"
          ]
          [
            (lib.filter (n: builtins.hasAttr n container))
            (lib.map (n: lib.nameValuePair n container.${n}))
            lib.listToAttrs
          ];
      };
      systemdConfig =
        let
          useMacvlan = systemd.macvlan or false;
          macvlanInterfaceName = "mv${toString lib.homelab.nameToIdMajor.${serviceName}}x${toString lib.homelab.nameToIdMinor.${serviceName}}";
          macvlanNetwork = lib.homelab.mkMacvlanSetup {
            hostName = serviceName;
            interfaceName = macvlanInterfaceName;
            netdevPriority = 30;
            networkPriority = 40;
            mainTableMetric = 1000;
            # Routing table ID: base offset of 1000 avoids reserved tables (253-255)
            # g * 256 ensures no overlap since id is 0-255
            policyTableId = 1000 + lib.homelab.nameToIdMajor.${serviceName} * 256 + lib.homelab.nameToIdMinor.${serviceName};
            policyPriority = 200;
            addPrefixRoute = false;
          };
        in
        {
          imports = [ extraConfig ] ++ map homelabServiceStorage storageNames;

          systemd = {
            targets."${serviceName}-requires" = requiresTarget;
            services = {
              "${serviceName}" = rec {
                aliases = [ "homelab-${serviceName}.service" ];
                enable = true;
                description = serviceName;
                wantedBy = lib.optional autoStart "multi-user.target";
                requires =
                  serviceRequires ++
                  [ "network-online.target" "${serviceName}-requires.target" ] ++
                  lib.optional useMacvlan "sys-subsystem-net-devices-${macvlanInterfaceName}.device";
                after = requires;
                path = systemd.path or [ ];
                script = lib.optionalString (systemd ? script) (systemd.script {
                  inherit serviceName uid gid storagePath containerOptions;
                  interface = if useMacvlan then macvlanInterfaceName else null;
                  ip = lib.homelab.nameToIp.${serviceName};
                  ip6 = lib.homelab.nameToIp6.${serviceName};
                });
                postStop = "systemctl restart ${serviceName}-backup";
              };
              "${serviceName}-backup" = backupService;
            };
            network = lib.mkIf useMacvlan macvlanNetwork;
          };
          networking.firewall.interfaces.${macvlanInterfaceName} = lib.mkIf useMacvlan {
            allowedTCPPorts = systemd.tcpPorts or [ ];
            allowedUDPPorts = systemd.udpPorts or [ ];
          };
        };
      serviceConfig = if isContainer then containerConfig else systemdConfig;
    in
    lib.optionalAttrs (machine.hostName == lib.homelab.nameToHost.${serviceName}) serviceConfig;
  importService = n:
    let
      i = (import ../services/${n}.nix) args;
    in
    if (isList i) then (map (f: homelabService f) i) else (homelabService ({ serviceName = n; } // i));
  serviceFileBaseNames =
    let
      serviceDir = readDir ../services;
    in
    map (n: lib.strings.removeSuffix ".nix" n) (filter (n: serviceDir.${n} == "regular" && (lib.strings.hasSuffix ".nix" n) && !(lib.strings.hasPrefix "." n)) (attrNames serviceDir));
in
{
  imports = lib.lists.flatten (map importService serviceFileBaseNames);
}
