# hostId: head -c4 /dev/urandom | od -A none -t x4
{ machineId, ... }:
let
  interleavedNuma = nodeCount: cpusPerNode:
    builtins.genList
      (node: builtins.genList (cpu: cpu * nodeCount + node) cpusPerNode)
      nodeCount;
  blockInterleavedNuma = nodeCount: cpusPerBlock: blocksPerNode:
    builtins.genList
      (node:
        builtins.concatLists
          (builtins.genList
            (block: builtins.genList (cpu: (block * nodeCount + node) * cpusPerBlock + cpu)
              cpusPerBlock
            )
            blocksPerNode
          )
      )
      nodeCount;
  defaults = {
    system = "x86_64-linux";
    hostName = machineId;
    nvidia = false;
    zfs = true;
    zfs-pools = [ ];
    clamav = true;
    fwupd = true;
    timeZone = "America/Denver";
  };
  machines = {
    d1 = defaults // {
      stateVersion = "23.05";
      hostId = "2bec4b05";
      # lan-interfaces = [ "eno1" "eno2" "eno3" "eno4" "enp5s0" ];
      lan-interfaces = [ "enp131s0d1" ];
      nvidia = true;
      zfs-pools = [ "d" "f" ];
      imports = [
        ../modules/x86.nix
        ../modules/image-update-check.nix
      ];
      numaCpus = interleavedNuma 2 36;
    };
    c1-1 = defaults // {
      stateVersion = "24.05";
      hostId = "dfc92a33";
      lan-interfaces = [ "eno1" "eno2" ];
      zfs-pools = [ "d" "m" ];
      imports = [
        ../modules/x86.nix
      ];
      numaCpus = blockInterleavedNuma 2 18 2;
    };
    c1-2 = defaults // {
      stateVersion = "24.05";
      hostId = "39810e52";
      lan-interfaces = [ "eno1" "eno2" ];
      zfs-pools = [ ];
      imports = [
        ../modules/x86.nix
      ];
      numaCpus = blockInterleavedNuma 2 14 2;
    };
    b1 = defaults // {
      stateVersion = "24.05";
      hostId = "8f150749";
      lan-interfaces = [ "enp1s0" ];
      zfs-pools = [ ];
      imports = [
        ../modules/x86.nix
        ../modules/nebula-sync.nix
        ../modules/ups.nix
      ];
    };
    pi-67cba1 = defaults // {
      system = "aarch64-linux";
      lan-interfaces = [ "end0" ];
      zfs = false;
      clamav = false;
      fwupd = true;
      stateVersion = "23.05";
      hostId = "62c05afa";
      imports = [
        ../modules/hardware/rpi.nix
        ../modules/cec.nix
      ];
    };
  };
in
machines.${machineId}
