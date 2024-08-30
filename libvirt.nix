with builtins;
let
  ip_net = "192.168.100";
  local_vm_addresses = import ./local-vm-addresses.nix;
in
{ config, pkgs, ... }:
let
  hosts = concatStringsSep "\n" (map
    (name:
      let value = local_vm_addresses."${name}"; in ''
        <host mac="${value.mac}" name="${name}" ip="${ip_net}.${toString value.ip}"/>
      '')
    (attrNames local_vm_addresses));
  net_file = pkgs.writeText "net-local.xml" ''
    <network>
      <name>local</name>
      <domain name="vm-local"/>
      <ip address="${ip_net}.1" netmask="255.255.255.0">
        <dhcp>
          <range start="${ip_net}.128" end="${ip_net}.254"/>
          ${hosts}
        </dhcp>
      </ip>
    </network>
  '';
in
{
  boot.kernelModules = [
    "vfio_pci"
    "vfio"
    "vfio_iommu_type1"
  ];
  boot.kernelParams = [
    "intel_iommu=on"
  ];

  system.activationScripts = {
    libvirt.text = ''
      ${pkgs.zfs}/bin/zfs list r/varlib/vm >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create r/varlib/vm
      ${pkgs.zfs}/bin/zfs list d/varlib/images >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create d/varlib/images
      ${pkgs.libvirt}/bin/virsh net-destroy local
      ${pkgs.libvirt}/bin/virsh net-undefine local
      ${pkgs.libvirt}/bin/virsh net-define ${net_file}
      ${pkgs.libvirt}/bin/virsh net-start local
      ${pkgs.libvirt}/bin/virsh net-autostart local
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
        packages = [
          (pkgs.OVMF.override {
            secureBoot = true;
            tpmSupport = true;
          }).fd
        ];
      };
    };
  };
}
