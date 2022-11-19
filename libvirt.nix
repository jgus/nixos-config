{ pkgs, ... }:

{
  system.activationScripts = {
    libvirt.text = ''
      ${pkgs.zfs}/bin/zfs list s/varlib/vm >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create s/varlib/vm
      ${pkgs.zfs}/bin/zfs list d/varlib/images >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create d/varlib/images
    '';
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu.swtpm.enable = true;
  };
}
