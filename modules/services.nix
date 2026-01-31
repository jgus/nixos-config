with builtins;
args@{ config, lib, machine, pkgs, ... }:
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
          autoStart = true;
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
          macvlanInterfaceName = lib.homelab.macvlanInterfaceName serviceName;
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
          imports = map homelabServiceStorage storageNames;

          systemd = {
            targets."${serviceName}-requires" = requiresTarget;
            services = {
              "${serviceName}" = rec {
                aliases = [ "homelab-${serviceName}.service" ];
                enable = true;
                description = serviceName;
                wantedBy = [ "multi-user.target" ];
                requires =
                  serviceRequires ++
                  [ "network-online.target" "${serviceName}-requires.target" ] ++
                  lib.optional useMacvlan "sys-subsystem-net-devices-${macvlanInterfaceName}.device";
                after = requires;
                path = systemd.path or [ ];
                script = systemd.script;
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
with lib.types;
let
  containerSubmodule = submodule {
    options = {
      capabilities = lib.mkOption {
        description = "Linux capabilities to add to the container";
        type = attrsOf bool;
        default = { };
      };
      configVolume = lib.mkOption {
        description = "Container path for config storage";
        type = str;
      };
      dependsOn = lib.mkOption {
        description = "Container dependencies (other containers this one depends on)";
        type = listOf str;
        default = [ ];
      };
      devices = lib.mkOption {
        description = "Devices to pass through to the container";
        type = listOf str;
        default = [ ];
      };
      entrypoint = lib.mkOption {
        description = "Custom container entrypoint";
        type = nullOr str;
        default = null;
      };
      entrypointOptions = lib.mkOption {
        description = "Container command arguments";
        type = listOf str;
        default = [ ];
      };
      environment = lib.mkOption {
        description = "Environment variables";
        type = attrsOf str;
        default = { };
      };
      environmentFiles = lib.mkOption {
        description = "Environment files to load";
        type = listOf path;
        default = [ ];
      };
      extraOptions = lib.mkOption {
        description = "Additional Container CLI options";
        type = listOf str;
        default = [ ];
      };
      image = lib.mkOption {
        description = "Container image URI";
        type = nullOr str;
        default = null;
      };
      imageFile = lib.mkOption {
        description = "Container image file";
        type = nullOr path;
        default = null;
      };
      imageStream = lib.mkOption {
        description = "Container image stream";
        type = nullOr path;
        default = null;
      };
      ports = lib.mkOption {
        description = "Exposed ports (format: 'port[:container_port][/protocol]')";
        type = listOf str;
        default = [ ];
      };
      privileged = lib.mkOption {
        description = "Whether to run container in privileged mode";
        type = bool;
        default = false;
      };
      pullImage = lib.mkOption {
        description = "Pull image configuration (see images/ directory)";
        type = nullOf attrs;
        default = null;
      };
      readOnly = lib.mkOption {
        description = "Whether to run container in read-only mode";
        type = bool;
        default = true;
      };
      tmpFs = lib.mkOption {
        description = "Temporary filesystem mounts";
        type = listOf str;
        default = [ ];
      };
      volumes = lib.mkOption {
        description = "Volume mounts (format: 'host:container[:options]')";
        type = listOf str;
        default = [ ];
      };
      workdir = lib.mkOption {
        description = "Container working directory";
        type = nullOr str;
        default = null;
      };
    };
  };

  systemdSubmodule = submodule {
    options = {
      macvlan = lib.mkOption {
        description = "Use macvlan networking";
        type = bool;
        default = false;
      };
      tcpPorts = lib.mkOption {
        description = "Open TCP ports";
        type = listOf (ints.u16);
        default = [ ];
      };
      udpPorts = lib.mkOption {
        description = "Open UDP ports";
        type = listOf (ints.u16);
        default = [ ];
      };
      path = lib.mkOption {
        description = "List of Nix packages to add to PATH";
        type = listOf path;
        default = [ ];
      };
      script = lib.mkOption {
        description = "Service startup script. Receives args: interface, ip, ip6, etc.";
        type = lines;
      };
    };
  };

  serviceSubmodule = submodule ({ name, config, ... }: {
    options = {
      enabled = lib.mkOption {
        description = "Whether to enable the ${name} service";
        type = bool;
        default = false;
      };
      name = lib.mkOption {
        description = "Service name";
        type = str;
        default = name;
      };
      requires = lib.mkOption {
        description = "Service dependencies (systemd units or mount points)";
        type = listOf str;
        default = [ ];
      };
      configStorage = lib.mkOption {
        description = "Enable configuration storage";
        type = bool;
        default = true;
      };
      extraStorage = lib.mkOption {
        description = "Additional storage paths or configurations";
        type = listOf str;
        default = [ ];
      };
      user = lib.mkOption {
        description = "Service user";
        type = str;
        default = "root";
      };
      group = lib.mkOption {
        description = "Service group";
        type = str;
        default = "root";
      };
      container = lib.mkOption {
        description = "Container-based service configuration";
        type = nullOr containerSubmodule;
        default = null;
      };
      systemd = lib.mkOption {
        description = "Generic systemd service configuration";
        type = nullOr systemdSubmodule;
        default = null;
      };
    };
  });

  mkServiceConfig = serviceConfig:
    if (serviceConfig.container == null && serviceConfig.systemd == null) then throw "`container` or `systemd` must be set" else
    if (serviceConfig.container != null && serviceConfig.systemd != null) then throw "`container` and `systemd` cannot both be set" else
    if (!serviceConfig.enabled) then { } else
    let
      serviceName = serviceConfig.name;
      uid = toString config.users.users.${serviceConfig.user}.uid;
      gid = toString config.users.groups.${serviceConfig.group}.gid;
      storageNames = serviceConfig.extraStorage ++ lib.optional serviceConfig.configStorage serviceName;
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
          autoStart = true;
          user = "${uid}:${gid}";
          volumes =
            [ "${pkgs.tzdata}/share/zoneinfo:/etc/zoneinfo:ro" ]
              ++ (container.volumes or [ ])
              ++ lib.optional serviceConfig.configStorage "${lib.homelab.storagePath serviceName}:${container.configVolume}";
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
            "capabilities"
            "dependsOn"
            "devices"
            "entrypoint"
            "environmentFiles"
            "image"
            "imageFile"
            "imageStream"
            "ports"
            "privileged"
            "workdir"
          ]
          [
            (lib.filter (n: hasAttr n container))
            (lib.map (n: lib.nameValuePair n container.${n}))
            lib.listToAttrs
          ];
      };
      systemdConfig =
        let
          useMacvlan = serviceConfig.systemd.macvlan or false;
          macvlanInterfaceName = lib.homelab.macvlanInterfaceName serviceName;
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
          systemd = {
            targets."${serviceName}-requires" = requiresTarget;
            services = {
              "${serviceName}" = rec {
                inherit (serviceConfig) path script;
                aliases = [ "homelab-${serviceName}.service" ];
                enable = true;
                description = serviceName;
                wantedBy = [ "multi-user.target" ];
                requires =
                  serviceConfig.requires ++
                  [ "network-online.target" "${serviceName}-requires.target" ] ++
                  lib.optional useMacvlan "sys-subsystem-net-devices-${macvlanInterfaceName}.device";
                after = requires;
                postStop = "systemctl restart ${serviceName}-backup";
              };
              "${serviceName}-backup" = backupService;
            };
            network = lib.mkIf useMacvlan macvlanNetwork;
          };
          networking.firewall.interfaces.${macvlanInterfaceName} = lib.mkIf useMacvlan {
            allowedTCPPorts = serviceConfig.systemd.tcpPorts;
            allowedUDPPorts = serviceConfig.systemd.udpPorts;
          };
        };
    in
    lib.homelab.recursiveUpdates [
      (if isContainer then containerConfig else systemdConfig)
    ] ++ (map homelabServiceStorage storageNames);

in
{
  options.homelab.services = lib.mkOption {
    description = "Homelab service configurations";
    type = attrsOf serviceSubmodule;
    default = { };
  };

  imports = [
    ./services/audiobookshelf.nix
    ./services/cloudflared.nix
    ./services/code-server.nix
    ./services/echo.nix
    ./services/ollama.nix
  ]
  ++ (lib.lists.flatten (map importService serviceFileBaseNames));

  config = lib.homelab.mkMergeByAttributes [
    # "homelab"
    "networking"
    "systemd"
    "virtualisation"
  ]
    (map mkServiceConfig (attrValues config.homelab.services));
}
