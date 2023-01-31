{ pkgs, ... }:

{
  system.activationScripts = {
    libvirt.text = ''
      ${pkgs.zfs}/bin/zfs list r/varlib/vm >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create r/varlib/vm
      ${pkgs.zfs}/bin/zfs list d/varlib/images >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create d/varlib/images
    '';
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      swtpm.enable = true;
      ovmf.packages = [ pkgs.OVMFFull.fd ];
    };
  };
}
