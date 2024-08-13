# hostId: head -c4 /dev/urandom | od -A none -t x4
let
  machine-id = builtins.readFile ./machine-id.nix;
  pw = import ./.secrets/passwords.nix;
  rpi = {
      arch = "rpi";
      lan-interface = "end0";
      zfs = false;
  };
  zwave-box = rpi // {
      imports = [ ./zwave-js-ui.nix ];
  };
  machine = {
    # Defaults
    hostName = machine-id;
    arch = "x86";
    nvidia = false;
    zfs = true;
    zfs-pools = [];
    clamav = pw ? gmail;
    imports = [];
  } // {
    d1 = {
      stateVersion = "23.05";
      hostId = "2bec4b05";
      # lan-interfaces = [ "eno1" "eno2" "eno3" "eno4" "enp5s0f0" "enp5s0f1" ];
      lan-interface = "enp5s0f0";
      nvidia = true;
      zfs-pools = [ "d" ];
      imports = [
        #./ddclient.nix
        
        ./www.nix
        ./zigbee2mqtt.nix
        ./home-assistant.nix
        ./esphome.nix
        ./frigate.nix
        ./transmission.nix
        ./sabnzbd.nix
        ./prowlarr.nix
        ./lidarr.nix
        ./radarr.nix
        ./sonarr.nix
        ./mylar.nix
        ./komga.nix
        ./minecraft.nix

        #./vm-vm1.nix

        ./userbox.nix
      ];
    };
    d2 = {
      stateVersion = "24.05";
      hostId = "b5d59608";
      zfs-pools = [];
      imports = [];
    };
    d3 = {
      stateVersion = "24.05";
      hostId = "d4f10aaf";
      zfs-pools = [];
      imports = [];
    };
    c1-1 = {
      stateVersion = "24.05";
      hostId = "dfc92a33";
      lan-interfaces = [ "eno1" "eno2" ];
      zfs-pools = [ "d" "m" ];
      imports = [];
    };
    c1-2 = {
      stateVersion = "24.05";
      hostId = "39810e52";
      lan-interfaces = [ "eno1" "eno2" ];
      zfs-pools = [];
      imports = [ ./userbox.nix ];
    };
    b1 = {
      stateVersion = "24.05";
      hostId = "8f150749";
      lan-interface = "enp1s0";
      zfs-pools = [];
      imports = [ ./machine/b1/ups.nix ];
    };
    pi-67cba1 = rpi // {
      stateVersion = "23.05";
      hostId = "62c05afa";
      imports = [ ./cec.nix ];
    };
    pi-67db40 = zwave-box // {
      stateVersion = "23.05";
      hostId = "1f758e73";
    };
    pi-67dbcd = zwave-box // {
      stateVersion = "23.05";
      hostId = "da46f0cf";
    };
    pi-67dc75 = zwave-box // {
      stateVersion = "23.05";
      hostId = "39a18894";
    };
  }."${machine-id}";
in
{
  fwupd = (machine.arch == "x86");
  python = (machine.arch == "x86");
} //
(if (machine ? lan-interfaces) then { lan-interface = "br0"; } else {}) //
machine
