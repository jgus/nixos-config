{ pkgs, lib, ... }:

with builtins;
let
  ### Settings
  name = "vm1";
  uuid = "99fefcc4-d5aa-4717-8dde-4fe5f0552d87";
  mem_gb = 16;
  mac = {
    external = "52:54:00:6e:b4:bc";
  };
  cpu = {
    cores = 8;
    threads = 2;
  };
  pci_devices = [
    { # GPU
      domain = "0000";
      bus = "04";
      slot = "00";
      function = "0";
      vendor = "0x10de";
      device = "0x1bb1";
    }
    { # Audio
      domain = "0000";
      bus = "04";
      slot = "00";
      function = "1";
      vendor = "0x10de";
      device = "0x10f0";
    }
  ];
  ### Derivations
  local_vm_addresses = import ./local-vm-addresses.nix;
  vcpupins = concatStringsSep "\n" (lib.lists.flatten (genList (core: genList (thread: ''
    <vcpupin vcpu="${toString (core*cpu.threads + thread)}" cpuset="${toString (1 + 2*core + 16*thread)}"/>
  '') cpu.threads) cpu.cores));
  hostdevs = concatStringsSep "\n" (map (d: ''
    <hostdev mode="subsystem" type="pci" managed="yes">
      <source>
        <address domain="0x${d.domain}" bus="0x${d.bus}" slot="0x${d.slot}" function="0x${d.function}"/>
      </source>
      <address type="pci" domain="0x${d.domain}" bus="0x${d.bus}" slot="0x${d.slot}" function="0x${d.function}"/>
    </hostdev>
  '') pci_devices);
  domain_xml = ''
    <domain type="kvm">
      <name>${name}</name>
      <uuid>${uuid}</uuid>
      <memory unit="GiB">${toString mem_gb}</memory>
      <vcpu placement="static">${toString (cpu.cores * cpu.threads)}</vcpu>
      <cpu mode="host-passthrough">
        <topology sockets="1" cores="${toString cpu.cores}" threads="${toString cpu.threads}"/>
      </cpu>
      <iothreads>4</iothreads>
      <cputune>
        ${vcpupins}
        <emulatorpin cpuset="24,26,28,30"/>
        <iothreadpin iothread="1" cpuset="16"/>
        <iothreadpin iothread="2" cpuset="18"/>
        <iothreadpin iothread="3" cpuset="20"/>
        <iothreadpin iothread="4" cpuset="22"/>
      </cputune>
      <os>
        <type arch="x86_64" machine="q35">hvm</type>
        <loader readonly="yes" secure="yes" type="pflash">/run/libvirt/nix-ovmf/OVMF_CODE.fd</loader>
        <nvram template="/run/libvirt/nix-ovmf/OVMF_VARS.fd">/var/lib/vm/${name}/VARS.fd</nvram>
      </os>
      <features>
        <acpi/>
        <apic/>
        <vmport state="off"/>
        <smm state="on"/>
      </features>
      <clock offset="localtime">
        <timer name="rtc" tickpolicy="catchup"/>
        <timer name="pit" tickpolicy="delay"/>
        <timer name="hpet" present="no"/>
      </clock>
      <pm>
        <suspend-to-mem enabled="no"/>
        <suspend-to-disk enabled="no"/>
      </pm>
      <devices>
        <emulator>/run/libvirt/nix-emulators/qemu-system-x86_64</emulator>
        <disk type="block" device="disk">
          <driver name="qemu" type="raw" discard="unmap"/>
          <source dev="/dev/zvol/r/varlib/vm/${name}/system"/>
          <target dev="sda" bus="scsi"/>
          <boot order="1"/>
        </disk>
        <!-- --> 
        <disk type="file" device="cdrom">
          <driver name="qemu" type="raw"/>
          <source file="/d/software/MSDN/Windows/Windows 11/Win11_23H2_English_x64v2.iso"/>
          <target dev="sdb" bus="sata"/>
          <readonly/>
          <boot order="2"/>
        </disk>
        <disk type="file" device="cdrom">
          <driver name="qemu" type="raw"/>
          <source file="/d/software/Drivers/virtio-win-0.1.240.iso"/>
          <target dev="sdc" bus="sata"/>
          <readonly/>
        </disk>
        <!-- -->
        <controller type="scsi" index="0" model="virtio-scsi"/>
        <controller type="sata" index="0"/>
        <controller type="virtio-serial" index="0"/>
        <interface type="direct">
          <mac address="${mac.external}"/>
          <source dev="enp5s0f0" mode="bridge"/>
          <model type="virtio"/>
        </interface>
        <interface type="network">
          <mac address="${local_vm_addresses.${name}.mac}"/>
          <source network="local"/>
          <model type="virtio"/>
        </interface>
        <channel type="spicevmc">
          <target type="virtio" name="com.redhat.spice.0"/>
          <address type="virtio-serial" controller="0" bus="0" port="1"/>
        </channel>
        <input type="tablet" bus="usb"/>
        <input type="mouse" bus="ps2"/>
        <input type="keyboard" bus="ps2"/>
        <tpm model="tpm-tis">
          <backend type="emulator" version="2.0"/>
        </tpm>
        <graphics type="spice" autoport="yes">
          <listen type="address"/>
        </graphics>
        <sound model="ich6"/>
        <audio id="1" type="spice"/>
        <video>
          <model type="qxl" ram="65536" vram="65536" vgamem="16384" heads="1" primary="yes"/>
        </video>
        ${hostdevs}
        <redirdev bus="usb" type="spicevmc"/>
        <memballoon model="virtio"/>
      </devices>
    </domain>
  '';
  domain_file = pkgs.writeText "domain.xml" domain_xml;
in
{
  imports = [ ./libvirt.nix ];

  system.activationScripts = {
    "vm-${name}".text = ''
      ${pkgs.zfs}/bin/zfs list r/varlib/vm/${name} >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create r/varlib/vm/${name}
      ${pkgs.zfs}/bin/zfs list r/varlib/vm/${name}/system >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create -b 16k -s -V 64G r/varlib/vm/${name}/system
      ${pkgs.libvirt}/bin/virsh define ${domain_file}
    '';
  };

  virtualisation.libvirtd.hooks = {
    qemu = {
      "${name}.sh" = let
        prepare_pci = concatStringsSep "\n" (
          (map (d: ''echo "${d.domain}:${d.bus}:${d.slot}.${d.function}" > "/sys/bus/pci/devices/${d.domain}:${d.bus}:${d.slot}.${d.function}/driver/unbind"'') pci_devices) ++ 
          (map (d: ''echo "${d.vendor} ${d.device}" > /sys/bus/pci/drivers/vfio-pci/new_id'') pci_devices)
        );
        release_pci = concatStringsSep "\n" (
          (map (d: ''echo "${d.vendor} ${d.device}" > /sys/bus/pci/drivers/vfio-pci/remove_id'') pci_devices) ++ 
          (map (d: ''echo 1 > "/sys/bus/pci/devices/${d.domain}:${d.bus}:${d.slot}.${d.function}/remove"'') pci_devices)
        );
      in
      pkgs.writeShellScript "${name}.sh" ''
        [ "$1" == "${name}" ] || exit 0
        case "$2" in
          "prepare")
            for x in system.slice user.slice init.scope
            do
              systemctl set-property --runtime -- $x AllowedCPUs=0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30
            done
            ${prepare_pci}
            ;;
          "release")
            ${release_pci}
            echo 1 > /sys/bus/pci/rescan
            for x in system.slice user.slice init.scope
            do
              systemctl set-property --runtime -- $x AllowedCPUs=0-31
            done
            ;;
        esac
      '';
    };
  };
}
