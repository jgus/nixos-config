# hostId: head -c4 /dev/urandom | od -A none -t x4
let
  machine-id = builtins.readFile ./machine-id.nix;
  pw = import ./.secrets/passwords.nix;
  addresses = import ./addresses.nix;
  zwave-box = {
      arch = "rpi";
      zfs = false;
      imports = [ ./zwave-js-ui.nix ];
  };
  machine = {
    # Defaults
    hostName = "${machine-id}";
    arch = "x86";
    nas-host = false;
    nvidia = false;
    zfs = true;
    zfs-pools = [];
    clamav = pw ? gmail;
    imports = [];
  } // {
    d1 = {
      stateVersion = "23.05";
      hostId = "2bec4b05";
      bridge-interfaces = [ "eno1" "eno2" "eno3" "eno4" "enp5s0f0" "enp5s0f1" ];
      nvidia = true;
      nas-host = true;
      zfs-pools = [ "d" ];
      imports = [
        #./ddclient.nix
        ./samba.nix
        ./landing.nix
        ./syncthing.nix
        ./www.nix
        ./ntp.nix
        ./mosquitto.nix
        ./zigbee2mqtt.nix
        ./home-assistant.nix
        ./esphome.nix
        ./frigate.nix
        ./plex.nix
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

        # ./offsite-josh-ws.nix
        # ./offsite-homeassistant.nix
        #./offsite-gustafson-nas.nix
        # ./sync-to-cloud.nix

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
      bridge-interfaces = [ "eno1" "eno2" ];
      zfs-pools = [ "d" ];
      imports = [ ./machine/c1-1/samba.nix ];
    };
    c1-2 = {
      stateVersion = "24.05";
      hostId = "39810e52";
      bridge-interfaces = [ "eno1" "eno2" ];
      zfs-pools = [];
      imports = [ ./userbox.nix ];
    };
    b1 = {
      stateVersion = "24.05";
      hostId = "8f150749";
      bridge-interfaces = [ "enp1s0" ];
      zfs-pools = [];
      imports = [ ./machine/b1/ups.nix ];
    };
    pi-67cba1 = {
      stateVersion = "23.05";
      hostId = "62c05afa";
      arch = "rpi";
      zfs = false;
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
  primary_interface = if (machine.arch == "rpi") then "end0" else "br0";
} //
(if (machine ? bridge-interfaces) then {
  bridge = {
    interfaces = machine.bridge-interfaces;
    mac = addresses.machines."${machine-id}".mac;
  };
} else {}) //
machine
