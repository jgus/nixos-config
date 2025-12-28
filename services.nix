with builtins;
let
  machine = import ./machine.nix;
  storagePath = name: "/service/${name}";
  storageBackupPath = name: "/storage/service/${name}";
  serviceDir = readDir ./services;
in
args@{ pkgs, lib, ... }:
let
  addresses = import ./addresses.nix { inherit lib; };
  serviceNames = map (n: lib.strings.removeSuffix ".nix" n) (filter (n: serviceDir.${n} == "regular" && (lib.strings.hasSuffix ".nix" n) && !(lib.strings.hasPrefix "." n)) (attrNames serviceDir));
  homelabServiceStorage = name:
    let
      path = storagePath name;
      backupPath = storageBackupPath name;
      zfsDeps = if machine.zfs then [ "zfs.target" ] else [ ];
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
    , docker ? { }
    , systemd ? { }
    , extraConfig ? { }
    ,
    }: { config, ... }:
    let
      serviceRequires = requires;
      uid = toString config.users.users.${user}.uid;
      gid = toString config.users.groups.${group}.gid;
      serviceRecord = addresses.records.${name};
      storageNames = extraStorage ++ lib.optional configStorage name;
      dockerOptions = addresses.dockerOptions name;
      isDocker = docker ? image || docker ? pullImage;

      # Shared service components used by both docker and systemd configs
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

      dockerConfig =
        let
          dockerImage =
            if docker ? pullImage
            then "${docker.pullImage.finalImageName}:${docker.pullImage.finalImageTag}"
            else docker.image;

          dockerImageFile =
            if docker ? pullImage
            then pkgs.dockerTools.pullImage docker.pullImage
            else docker.imageFile or null;
        in
        {
          imports = [ ./docker.nix extraConfig ] ++ map homelabServiceStorage storageNames;

          systemd = {
            targets."${name}-requires" = requiresTarget;
            services = {
              "docker-${name}" = {
                aliases = [ "${name}.service" ];
                serviceConfig.Restart = pkgs.lib.mkForce "no";
                postStop = "systemctl restart ${name}-backup";
              };
              "${name}-update" = lib.mkIf (!(docker ? imageFile || docker ? imageStream || docker ? pullImage)) {
                path = [ pkgs.docker ];
                script = ''
                  if docker pull ${dockerImage} | grep "Status: Downloaded"
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
            image = dockerImage;
            autoStart = autoStart;
            user = "${uid}:${gid}";
            volumes =
              (let v = docker.volumes or [ ]; in if isFunction v then v storagePath else v) ++
                lib.optional configStorage "${storagePath name}:${docker.configVolume}";
            extraOptions = docker.extraOptions or [ ] ++ dockerOptions;
            entrypoint = docker.entrypoint or null;
            cmd = docker.entrypointOptions or [ ];
          }
          // lib.optionalAttrs (dockerImageFile != null) { imageFile = dockerImageFile; }
          // lib.optionalAttrs (docker ? imageStream) { inherit (docker) imageStream; }
          // lib.optionalAttrs (docker ? dependsOn) { inherit (docker) dependsOn; }
          // lib.optionalAttrs (docker ? environment) { inherit (docker) environment; }
          // lib.optionalAttrs (docker ? environmentFiles) { inherit (docker) environmentFiles; }
          // lib.optionalAttrs (docker ? ports) { inherit (docker) ports; };
        };
      systemdConfig =
        let
          useMacvlan = systemd.macvlan or false;
          macvlanInterfaceName = "mv${toString serviceRecord.g}x${toString serviceRecord.id}";
          macvlanNetwork =
            let
              # Routing table ID: base offset of 1000 avoids reserved tables (253-255)
              # g * 256 ensures no overlap since id is 0-255
              routeTableId = 1000 + serviceRecord.g * 256 + serviceRecord.id;
            in
            {
              # Create the macvlan netdev
              netdevs."30-${macvlanInterfaceName}" = {
                netdevConfig = {
                  Kind = "macvlan";
                  Name = macvlanInterfaceName;
                  MACAddress = serviceRecord.mac;
                };
                macvlanConfig = {
                  Mode = "bridge";
                };
              };

              # Attach macvlan to physical interface
              networks."05-${machine.lan-interface}".macvlan = [ macvlanInterfaceName ];

              # Configure the macvlan network
              networks."40-${macvlanInterfaceName}" = {
                matchConfig.Name = macvlanInterfaceName;
                networkConfig = {
                  DHCP = "no";
                  IPv6AcceptRA = "yes";
                  LinkLocalAddressing = "ipv6";
                };
                # Use AddPrefixRoute=false to prevent auto-generated kernel routes
                # This ensures lan0 (host) routes are preferred over service macvlan routes
                addresses = [
                  {
                    Address = "${serviceRecord.ip}/${toString addresses.network.prefixLength}";
                    AddPrefixRoute = false;
                  }
                  {
                    Address = "${serviceRecord.ip6}/${toString addresses.network.prefix6Length}";
                    AddPrefixRoute = false;
                  }
                ];
                routes = [
                  # Routes in main table (for direct connectivity)
                  {
                    Destination = "${addresses.network.prefix}0.0/${toString addresses.network.prefixLength}";
                    Metric = 1000;
                  }
                  {
                    Destination = "${addresses.network.prefix6}/${toString addresses.network.prefix6Length}";
                    Metric = 1000;
                  }
                  # Routes in custom table for source-based policy routing
                  {
                    Destination = "${addresses.network.prefix}0.0/${toString addresses.network.prefixLength}";
                    Table = routeTableId;
                  }
                  {
                    Destination = "0.0.0.0/0";
                    Gateway = addresses.network.defaultGateway;
                    Table = routeTableId;
                  }
                  {
                    Destination = "${addresses.network.prefix6}/${toString addresses.network.prefix6Length}";
                    Table = routeTableId;
                  }
                ];
                # Source-based policy routing rules - declarative!
                routingPolicyRules = [
                  {
                    From = serviceRecord.ip;
                    Table = routeTableId;
                    Priority = 200;
                  }
                  {
                    From = serviceRecord.ip6;
                    Table = routeTableId;
                    Priority = 200;
                  }
                ];
              };
            };
        in
        {
          imports = [ extraConfig ] ++ map homelabServiceStorage storageNames;

          systemd = {
            targets."${name}-requires" = requiresTarget;
            services = {
              "${name}" = rec {
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
                  inherit name uid gid storagePath dockerOptions;
                  interface = if useMacvlan then macvlanInterfaceName else null;
                  ip = serviceRecord.ip;
                  ip6 = serviceRecord.ip6;
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
