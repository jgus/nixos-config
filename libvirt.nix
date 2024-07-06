{ pkgs, ... }:

{
  environment.etc = {
    "vm/local-net.xml".text = ''
      <network>
        <name>local</name>
        <domain name="local"/>
        <ip address="192.168.100.1" netmask="255.255.255.0">
          <dhcp>
            <range start="192.168.100.128" end="192.168.100.254"/>
            <host mac="d4:7b:31:69:c4:1d" name="vm1" ip="192.168.100.2"/>
          </dhcp>
        </ip>
      </network>
    '';
  };

  system.activationScripts = {
    libvirt.text = ''
      ${pkgs.zfs}/bin/zfs list r/varlib/vm >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create r/varlib/vm
      ${pkgs.zfs}/bin/zfs list d/varlib/images >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create d/varlib/images
      ${pkgs.libvirt}/bin/virsh net-info local >/dev/null 2>&1 || ${pkgs.libvirt}/bin/virsh net-create /etc/vm/local-net.xml
    '';
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf = {
        enable = true;
        packages = [(pkgs.OVMF.override {
          secureBoot = true;
          tpmSupport = true;
        }).fd];
      };
    };
  };
}
