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
        };
      }) [
      "backup"
      "external"
      "offsite"
      "photos"
      "projects"
      "scratch"
      "service"
      "software"
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
in
{ lib, pkgs, ... }:
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

  fileSystems = listToAttrs (lib.lists.flatten (map (name: if (isLocal name) then (bindMount name) else [ ]) (attrNames mapping)));
  services.nfs.server.exports = lib.concatStrings (map (name: if (isLocal name) then (nfsExport name) else "") (attrNames mapping));
  systemd.mounts = lib.lists.flatten (map (name: if (isLocal name) then [ ] else [ (systemdMount name) ]) (attrNames mapping));
  systemd.automounts = lib.lists.flatten (map (name: if (isLocal name) then [ ] else [ (systemdAutomount name) ]) (attrNames mapping));
}
