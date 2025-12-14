# hostId: head -c4 /dev/urandom | od -A none -t x4
with builtins;
let
  machineIdEnv = builtins.getEnv "MACHINE_ID";
  machineId = if (machineIdEnv != "") then machineIdEnv else (builtins.readFile ./machine-id.nix);
  pw = import ./.secrets/passwords.nix;
  rpi = {
    arch = "rpi";
    lan-interface = "end0";
    zfs = false;
  };
  machine = {
    # Defaults
    hostName = machineId;
    arch = "x86";
    nvidia = false;
    zfs = true;
    zfs-pools = [ ];
    clamav = pw ? smtp2go;
    imports = [ ];
  } // (getAttr machineId {
    d1 = {
      stateVersion = "23.05";
      hostId = "2bec4b05";
      # lan-interfaces = [ "eno1" "eno2" "eno3" "eno4" "enp5s0" ];
      lan-interface = "enp131s0d1";
      nvidia = true;
      zfs-pools = [ "d" "f" "s" ];
      imports = [
        #./vm-vm1.nix
      ];
      numaCpus = [
        [ 0 2 4 6 8 10 12 14 16 18 20 22 24 26 28 30 32 34 36 38 40 42 44 46 48 50 52 54 56 58 60 62 64 66 68 70 ]
        [ 1 3 5 7 9 11 13 15 17 19 21 23 25 27 29 31 33 35 37 39 41 43 45 47 49 51 53 55 57 59 61 63 65 67 69 71 ]
      ];
    };
    c1-1 = {
      stateVersion = "24.05";
      hostId = "dfc92a33";
      lan-interfaces = [ "eno1" "eno2" ];
      zfs-pools = [ "d" "m" ];
      imports = [ ];
    };
    c1-2 = {
      stateVersion = "24.05";
      hostId = "39810e52";
      lan-interfaces = [ "eno1" "eno2" ];
      zfs-pools = [ ];
    };
    b1 = {
      stateVersion = "24.05";
      hostId = "8f150749";
      lan-interface = "enp1s0";
      zfs-pools = [ ];
      imports = [
        ./machine/b1/nebula-sync.nix
        ./machine/b1/ups.nix
      ];
    };
    pi-67cba1 = rpi // {
      stateVersion = "23.05";
      hostId = "62c05afa";
      imports = [ ./cec.nix ];
    };
  });
in
{
  system = getAttr machine.arch {
    rpi = "aarch64-linux";
    x86 = "x86_64-linux";
  };
  fwupd = (machine.arch == "x86");
  python = (machine.arch == "x86");
}
//
(if (machine ? lan-interfaces) then { lan-interface = "br0"; } else { })
  //
machine
