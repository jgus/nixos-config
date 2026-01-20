with builtins;
let
  storagePath = name: "/service/${name}";
  storageBackupPath = name: "/storage/service/${name}";
  serviceDir = readDir ../services;
in
args@{ addresses, lib, machine, pkgs, ... }:
let
  serviceNames = map (n: lib.strings.removeSuffix ".nix" n) (filter (n: serviceDir.${n} == "regular" && (lib.strings.hasSuffix ".nix" n) && !(lib.strings.hasPrefix "." n)) (attrNames serviceDir));
  homelabServiceStorage = name:
    let
      path = storagePath name;
      backupPath = storageBackupPath name;
      zfsDeps = lib.optional machine.zfs "zfs.target";
    in
    {
      systemd.services = {
        "service-storage-${name}-setup" = {
          requires = zfsDeps;
          after = zfsDeps;
          path = [ pkgs.rsync ] ++ lib.optional machine.zfs pkgs.zfs;
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
    , container ? { }
    , systemd ? { }
    , extraConfig ? { }
    ,
    }@args: { config, ... }:
    let
      serviceRequires = requires;
      uid = toString config.users.users.${user}.uid;
      gid = toString config.users.groups.${group}.gid;
      storageNames = extraStorage ++ lib.optional configStorage name;
      argsContainer = args.container or { };
      container = argsContainer // (if argsContainer ? pullImage then {
        image = "${argsContainer.pullImage.finalImageName}:${argsContainer.pullImage.finalImageTag}";
        imageFile = pkgs.dockerTools.pullImage argsContainer.pullImage;
      } else { });
      containerOptions = lib.ext.containerOptions name;
      isContainer = container ? image;

      # Shared service components used by both container and systemd configs
      requiresTarget = rec {
        requires = map (s: "service-storage-${s}-setup.service") storageNames;
        after = requires;
        requiredBy = [ "${name}.service" ];
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

        ext.container.enable = true;

        systemd = {
          targets."${name}-requires" = requiresTarget;
          services = {
            "${name}" = {
              aliases = [ "homelab-${name}.service" ];
              serviceConfig.Restart = pkgs.lib.mkForce "no";
              postStop = "systemctl restart ${name}-backup";
            };
            "${name}-update" = lib.mkIf (!(container ? imageFile || container ? imageStream || container ? pullImage)) {
              path = [ containerConfig.package ];
              script = ''
                if ${containerConfig.executable} pull ${container.image} | grep "Status: Downloaded"
                then
                  systemctl restart ${name}
                fi
              '';
              serviceConfig = { Type = "exec"; };
              startAt = "hourly";
            };
            "${name}-backup" = backupService;
          };
        };
        virtualisation.oci-containers.containers.${name} = {
          serviceName = name;
          autoStart = autoStart;
          user = "${uid}:${gid}";
          volumes =
            (let v = container.volumes or [ ]; in if isFunction v then v storagePath else v) ++
              lib.optional configStorage "${storagePath name}:${container.configVolume}";
          extraOptions =
            (container.extraOptions or [ ])
              ++ containerOptions
              ++ (lib.optional (container.readOnly or true) "--read-only")
              ++ (map (value: "--tmpfs=${value}") (container.tmpFs or [ ]));
          cmd = container.entrypointOptions or [ ];
          environment = {
            TZ = config.time.timeZone;
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
          macvlanInterfaceName = "mv${toString lib.ext.nameToIdMajor.${name}}x${toString lib.ext.nameToIdMinor.${name}}";
          macvlanNetwork = lib.ext.mkMacvlanSetup {
            hostName = name;
            interfaceName = macvlanInterfaceName;
            netdevPriority = 30;
            networkPriority = 40;
            mainTableMetric = 1000;
            # Routing table ID: base offset of 1000 avoids reserved tables (253-255)
            # g * 256 ensures no overlap since id is 0-255
            policyTableId = 1000 + lib.ext.nameToIdMajor.${name} * 256 + lib.ext.nameToIdMinor.${name};
            policyPriority = 200;
            addPrefixRoute = false;
          };
        in
        {
          imports = [ extraConfig ] ++ map homelabServiceStorage storageNames;

          systemd = {
            targets."${name}-requires" = requiresTarget;
            services = {
              "${name}" = rec {
                aliases = [ "homelab-${name}.service" ];
                enable = true;
                description = name;
                wantedBy = lib.optional autoStart "multi-user.target";
                requires =
                  serviceRequires ++
                  [ "network-online.target" "${name}-requires.target" ] ++
                  lib.optional useMacvlan "sys-subsystem-net-devices-${macvlanInterfaceName}.device";
                after = requires;
                path = systemd.path or [ ];
                script = lib.optionalString (systemd ? script) (systemd.script {
                  inherit name uid gid storagePath containerOptions;
                  interface = if useMacvlan then macvlanInterfaceName else null;
                  ip = lib.ext.nameToIp.${name};
                  ip6 = lib.ext.nameToIp6.${name};
                });
                postStop = "systemctl restart ${name}-backup";
              };
              "${name}-backup" = backupService;
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
    lib.optionalAttrs (machine.hostName == lib.ext.nameToHost.${name}) serviceConfig;
  importService = n:
    let
      i = (import ../services/${n}.nix) args;
    in
    if (isList i) then (map (f: homelabService f) i) else (homelabService ({ name = n; } // i));
in
{
  imports = lib.lists.flatten (map importService serviceNames);
}
