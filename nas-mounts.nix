{ pkgs, ... }:

let
  commonMountOptions = {
    type = "nfs";
    mountConfig = {
      Options = "noatime";
    };
  };
  commonAutoMountOptions = {
    wantedBy = [ "multi-user.target" ];
    automountConfig = {
      TimeoutIdleSec = "600";
    };
  };
in
{
  services.rpcbind.enable = true;
  
  environment.systemPackages = with pkgs; [
    nfs-utils
  ];

  systemd.mounts = [
    (commonMountOptions // {
      what = "nas:/export";
      where = "/nas";
    })
  ];

  systemd.automounts = [
    (commonAutoMountOptions // { where = "/nas"; })
  ];
}
