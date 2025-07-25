# hostId: head -c4 /dev/urandom | od -A none -t x4
let
  machine-id = builtins.readFile ./machine-id.nix;
  pw = import ./.secrets/passwords.nix;
  rpi = {
    arch = "rpi";
    lan-interface = "end0";
    zfs = false;
  };
  machine = {
    # Defaults
    hostName = machine-id;
    arch = "x86";
    nvidia = false;
    zfs = true;
    zfs-pools = [ ];
    clamav = pw ? smtp2go;
    imports = [ ];
  } // {
    d1 = {
      stateVersion = "23.05";
      hostId = "2bec4b05";
      # lan-interfaces = [ "eno1" "eno2" "eno3" "eno4" "enp5s0" ];
      lan-interface = "enp5s0";
      nvidia = true;
      zfs-pools = [ "d" "f" ];
      imports = [
        #./vm-vm1.nix
      ];
    };
    d2 = {
      stateVersion = "24.05";
      hostId = "b5d59608";
      zfs-pools = [ ];
      imports = [ ];
    };
    d3 = {
      stateVersion = "24.05";
      hostId = "d4f10aaf";
      zfs-pools = [ ];
      imports = [ ];
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
      imports = [ ./machine/b1/ups.nix ];
    };
    pi-67cba1 = rpi // {
      stateVersion = "23.05";
      hostId = "62c05afa";
      imports = [ ./cec.nix ];
    };
  }."${machine-id}";
in
{
  fwupd = (machine.arch == "x86");
  python = (machine.arch == "x86");
} //
(if (machine ? lan-interfaces) then { lan-interface = "br0"; } else { }) //
machine
