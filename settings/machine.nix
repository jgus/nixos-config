# hostId: head -c4 /dev/urandom | od -A none -t x4
{ machineId, ... }:
let
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
      numaCpus = [
        [ 0 2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 ]
        [ 1 3 5 7 9 11 13 15 17 19 21 23 25 27 29 31 33 35 37 39 41 43 45 47 49 51 53 55 57 59 61 63 65 67 69 71 ]
      ];
    };
    c1-1 = defaults // {
      stateVersion = "24.05";
      hostId = "dfc92a33";
      lan-interfaces = [ "eno1" "eno2" ];
      zfs-pools = [ "d" "m" ];
      imports = [
        ../modules/x86.nix
      ];
    };
    c1-2 = defaults // {
      stateVersion = "24.05";
      hostId = "39810e52";
      lan-interfaces = [ "eno1" "eno2" ];
      zfs-pools = [ ];
      imports = [
        ../modules/x86.nix
      ];
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
