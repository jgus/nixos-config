with builtins;
{ config, lib, pkgs, machine, addresses, ... }:
let
  s3Urls = {
    cloud = "s3:https://s3.us-west-004.backblazeb2.com/jgus-backup";
    garage = "s3:http://garage.${addresses.network.domain}:3900/backup";
  };
  mapping =
    (listToAttrs (map
      (x: {
        name = x;
        value = {
          machine = "c1-1";
          path = "/storage/${x}";
          backup = [ "garage" "cloud" ];
        };
      }) [
      "photos"
      "projects"
      "service"
    ])) //
    (listToAttrs (map
      (x: {
        name = x;
        value = {
          machine = "c1-1";
          path = "/storage/${x}";
          backup = [ "garage" ];
        };
      }) [
      "owncloud"
      "software"
    ])) //
    (listToAttrs (map
      (x: {
        name = x;
        value = {
          machine = "c1-1";
          path = "/storage/${x}";
        };
      }) [
      "backup"
      "external"
      "offsite"
      "scratch"
      "tmp"
    ])) //
    (listToAttrs (map
      (x: {
        name = "home-${x}";
        value = {
          machine = "c1-1";
          path = "/home/${x}";
          target = "/home/${x}";
          backup = [ "garage" "cloud" ];
        };
      }) [
      "josh"
      "gustafson"
      "nathaniel"
    ])) //
    {
      media = {
        machine = "c1-1";
        path = "/storage/media";
      };
      frigate = {
        machine = "d1";
        path = "/storage/frigate";
      };
    };
  isLocal = name: let m = getAttr name mapping; in (m.machine == machine.hostName);
  target = name: let m = getAttr name mapping; in (if (m ? target) then m.target else "/storage/" + name);
  bindMount = name:
    let m = getAttr name mapping; in (if ((target name) == m.path) then [ ] else [
      {
        name = target name;
        value = {
          device = m.path;
          options = [ "rbind" ];
        };
      }
    ]);
  systemdMount = name:
    let m = getAttr name mapping; in {
      type = "nfs";
      mountConfig = {
        Options = "noatime,bg";
      };
      what = "${m.machine}:${m.path}";
      where = target name;
    };
  systemdAutomount = name:
    {
      wantedBy = [ "multi-user.target" ];
      automountConfig = {
        TimeoutIdleSec = "600";
      };
      where = target name;
    };
  scaledKeepFlags = base: scale:
    let
      daily = base;
      weekly = ceil (base * scale / 7.0);
      monthly = ceil (base * scale * scale / (365.0 / 12));
      yearly = ceil (base * scale * scale * scale / 365.0);
    in
    [
      "--keep-daily=${toString daily}"
      "--keep-weekly=${toString weekly}"
      "--keep-monthly=${toString monthly}"
      "--keep-yearly=${toString yearly}"
    ];
  nfsExport = name:
    let m = getAttr name mapping; in ''
      ${m.path} ${addresses.network.prefix}${toString addresses.group.servers}.0/24(rw,crossmnt,no_root_squash)
    '';
  backupPath = name: (lib.lists.flatten (map (i: if ((isLocal i) && (mapping.${i} ? backup) && (elem name mapping.${i}.backup)) then [ (target i) ] else [ ]) (attrNames mapping)));
  backupPaths = {
    garage = backupPath "garage";
    cloud = backupPath "cloud";
  };
in
# trace (toJSON backupPaths.garage)
{
  services.nfs.server.enable = true;
  services.rpcbind.enable = true;
  networking.firewall = {
    allowedTCPPorts = [
      2049 # rbind
      5357 # wsdd
    ];
    allowedUDPPorts = [ 3702 ]; # wsdd
  };

  environment.systemPackages = with pkgs; [
    nfs-utils
    (writeShellScriptBin "restic-cloud" ''
      set -a
      source ${config.sops.secrets."restic/cloud/env".path}
      set +a
      export RESTIC_PASSWORD_FILE=${config.sops.secrets."restic/cloud/password".path}
      export RESTIC_REPOSITORY="${s3Urls.cloud}"
      exec ${restic}/bin/restic "$@"
    '')
    (writeShellScriptBin "restic-garage" ''
      set -a
      source ${config.sops.secrets."restic/garage/env".path}
      set +a
      export RESTIC_PASSWORD_FILE=${config.sops.secrets."restic/garage/password".path}
      export RESTIC_REPOSITORY="${s3Urls.garage}"
      exec ${restic}/bin/restic "$@"
    '')
  ];

  fileSystems =
    listToAttrs (lib.lists.flatten (map (name: if (isLocal name) then (bindMount name) else [ ]) (attrNames mapping)))
    // lib.optionalAttrs (isLocal "tmp") { "/storage/tmp" = { device = "tmpfs"; fsType = "tmpfs"; }; };
  services.nfs.server.exports = lib.concatStrings (map (name: if (isLocal name) then (nfsExport name) else "") (attrNames mapping));
  systemd.mounts = lib.lists.flatten (map (name: if (isLocal name) then [ ] else [ (systemdMount name) ]) (attrNames mapping));
  systemd.automounts = lib.lists.flatten (map (name: if (isLocal name) then [ ] else [ (systemdAutomount name) ]) (attrNames mapping));

  services.restic.backups =
    lib.optionalAttrs ((length backupPaths.garage) > 0)
      {
        garage = {
          initialize = true;
          paths = backupPaths.garage;
          repository = s3Urls.garage;
          environmentFile = config.sops.secrets."restic/garage/env".path;
          passwordFile = config.sops.secrets."restic/garage/password".path;
          extraBackupArgs = [ "-v" "--compression=max" ];
          pruneOpts = [ "-v" ] ++ (scaledKeepFlags 20 6);
        };
      }
    //
    lib.optionalAttrs ((length backupPaths.cloud) > 0) {
      cloud = {
        initialize = true;
        paths = backupPaths.cloud;
        repository = s3Urls.cloud;
        environmentFile = config.sops.secrets."restic/cloud/env".path;
        passwordFile = config.sops.secrets."restic/cloud/password".path;
        extraBackupArgs = [ "-v" "--compression=max" ];
        pruneOpts = [ "-v" ] ++ (scaledKeepFlags 3 6);
      };
    };

  sops.secrets = {
    "restic/cloud/env" = { };
    "restic/cloud/password" = { };
    "restic/garage/env" = { };
    "restic/garage/password" = { };
  };
}
