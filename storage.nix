with builtins;
let
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
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
    {
      media = {
        machine = "c1-1";
        path = "/storage/media";
      };
      frigate = {
        machine = "d1";
        path = "/storage/frigate";
      };
      home = {
        machine = "c1-1";
        path = "/home";
        target = "/home";
        backup = [ "garage" "cloud" ];
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
  nfsExport = name:
    let m = getAttr name mapping; in ''
      ${m.path} ${addresses.network.prefix}${toString addresses.group.servers}.0/24(rw,crossmnt,no_root_squash)
    '';
  systemdMount = name:
    let m = getAttr name mapping; in {
      type = "nfs";
      mountConfig = {
        Options = "noatime";
      };
      what = "${m.machine}:${m.path}";
      where = target name;
    };
  systemdAutomount = name:
    let m = getAttr name mapping; in {
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
in
{ lib, pkgs, ... }:
let
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
  ];

  fileSystems =
    listToAttrs (lib.lists.flatten (map (name: if (isLocal name) then (bindMount name) else [ ]) (attrNames mapping)))
    // (if (isLocal "tmp") then { "/storage/tmp" = { device = "tmpfs"; fsType = "tmpfs"; }; } else { });
  services.nfs.server.exports = lib.concatStrings (map (name: if (isLocal name) then (nfsExport name) else "") (attrNames mapping));
  systemd.mounts = lib.lists.flatten (map (name: if (isLocal name) then [ ] else [ (systemdMount name) ]) (attrNames mapping));
  systemd.automounts = lib.lists.flatten (map (name: if (isLocal name) then [ ] else [ (systemdAutomount name) ]) (attrNames mapping));

  services.restic.backups =
    (if ((length backupPaths.garage) > 0) then {
      garage = {
        initialize = true;
        paths = backupPaths.garage;
        repository = (readFile "/etc/nixos/.secrets/restic/garage/repository");
        environmentFile = "/etc/nixos/.secrets/restic/garage/env";
        passwordFile = "/etc/nixos/.secrets/restic/garage/password";
        extraBackupArgs = [ "-v" "--compression=max" ];
        pruneOpts = [ "-v" ] ++ (scaledKeepFlags 20 6);
      };
    } else { })
    //
    (if ((length backupPaths.cloud) > 0) then {
      cloud = {
        initialize = true;
        paths = backupPaths.cloud;
        repository = (readFile "/etc/nixos/.secrets/restic/cloud/repository");
        environmentFile = "/etc/nixos/.secrets/restic/cloud/env";
        passwordFile = "/etc/nixos/.secrets/restic/cloud/password";
        extraBackupArgs = [ "-v" "--compression=max" ];
        pruneOpts = [ "-v" ] ++ (scaledKeepFlags 3 6);
      };
    } else { });
}
