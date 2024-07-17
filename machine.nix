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
    pi-67db40 = zwave-box // {
      hostId = "1f758e73";
    };
    pi-67dbcd = zwave-box // {
      hostId = "da46f0cf";
    };
    pi-67dc75 = zwave-box // {
      hostId = "39a18894";
    };
  }."${machine-id}";
in
machine
