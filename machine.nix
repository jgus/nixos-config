# hostId: head -c4 /dev/urandom | od -A none -t x4
let
  machine-id = import ./.machine-id.nix; # file contains just a quoted string
  default = {
    hostName = "${machine-id}";
    arch = "x86";
    zfs = true;
    imports = [];
  };
  zwave-box = {
      arch = "rpi";
      zfs = false;
      imports = [ ./zwave-js-ui.nix ];
  };
  machine = default // {
    d1 = {
      stateVersion = "23.05";
      hostId = "2bec4b05";
      imports = [ ./cec.nix ];
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
} // machine
