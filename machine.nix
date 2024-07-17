# hostId: head -c4 /dev/urandom | od -A none -t x4
let
  default = {
    arch = "x86";
    zfs = true;
    imports = [];
  };
  machine = default // {
    pi-67dc75 = {
      hostName = "pi-67dc75";
      hostId = "39a18894";
      arch = "rpi";
      zfs = false;
      imports = [ ./zwave-js-ui.nix ];
    };
  }."${import ./.machine-id.nix}"; # file contains just a quoted string
in
machine
