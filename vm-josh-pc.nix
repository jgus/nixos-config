{ pkgs, ... }:

{
  imports = [ ./libvirt.nix ];

  boot = {
    initrd.kernelModules = [
      "vfio_pci"
      "vfio"
      "vfio_iommu_type1"
      "vfio_virqfd"
    ];
    kernelParams = [
      "intel_iommu=on"
      "iommu=pt"
      "vfio-pci.ids=10de:2704,10de:22bb,1912:0014,8086:a282"
      "isolcpus=2-17,20-35"
      "nohz_full=2-17,20-35"
    ];
  };

  environment.etc = {
    "vm/josh-pc.xml".text = ''
      <domain type="kvm">
        <name>josh-pc</name>
        <uuid>99fefcc4-d5aa-4717-8dde-4fe5f0552d87</uuid>
        <memory unit="GiB">96</memory>
        <currentMemory unit="GiB">96</currentMemory>
        <vcpu placement="static">32</vcpu>
        <iothreads>2</iothreads>
        <cputune>
          <vcpupin vcpu="0" cpuset="2"/>
          <vcpupin vcpu="1" cpuset="20"/>
          <vcpupin vcpu="2" cpuset="3"/>
          <vcpupin vcpu="3" cpuset="21"/>
          <vcpupin vcpu="4" cpuset="4"/>
          <vcpupin vcpu="5" cpuset="22"/>
          <vcpupin vcpu="6" cpuset="5"/>
          <vcpupin vcpu="7" cpuset="23"/>
          <vcpupin vcpu="8" cpuset="6"/>
          <vcpupin vcpu="9" cpuset="24"/>
          <vcpupin vcpu="10" cpuset="7"/>
          <vcpupin vcpu="11" cpuset="25"/>
          <vcpupin vcpu="12" cpuset="8"/>
          <vcpupin vcpu="13" cpuset="26"/>
          <vcpupin vcpu="14" cpuset="9"/>
          <vcpupin vcpu="15" cpuset="27"/>
          <vcpupin vcpu="16" cpuset="10"/>
          <vcpupin vcpu="17" cpuset="28"/>
          <vcpupin vcpu="18" cpuset="11"/>
          <vcpupin vcpu="19" cpuset="29"/>
          <vcpupin vcpu="20" cpuset="12"/>
          <vcpupin vcpu="21" cpuset="30"/>
          <vcpupin vcpu="22" cpuset="13"/>
          <vcpupin vcpu="23" cpuset="31"/>
          <vcpupin vcpu="24" cpuset="14"/>
          <vcpupin vcpu="25" cpuset="32"/>
          <vcpupin vcpu="26" cpuset="15"/>
          <vcpupin vcpu="27" cpuset="33"/>
          <vcpupin vcpu="28" cpuset="16"/>
          <vcpupin vcpu="29" cpuset="34"/>
          <vcpupin vcpu="30" cpuset="17"/>
          <vcpupin vcpu="31" cpuset="35"/>
          <emulatorpin cpuset="0,1"/>
          <iothreadpin iothread="1" cpuset="18"/>
          <iothreadpin iothread="2" cpuset="19"/>
        </cputune>
        <os>
          <type arch="x86_64" machine="q35">hvm</type>
          <loader readonly="yes" secure="yes" type="pflash">/run/libvirt/nix-ovmf/OVMF_CODE.fd</loader>
          <nvram template="/run/libvirt/nix-ovmf/OVMF_VARS.fd">/var/lib/vm/josh-pc/VARS.fd</nvram>
        </os>
        <features>
          <acpi/>
          <apic/>
          <vmport state="off"/>
          <smm state="on"/>
          <hyperv>
            <vendor_id state='on' value='randomid'/>
          </hyperv>
          <kvm>
            <hidden state='on'/>
          </kvm>
          <ioapic driver='kvm'/>
        </features>
        <cpu mode="host-passthrough">
          <topology sockets="1" cores="16" threads="2"/>
        </cpu>
        <clock offset="localtime">
          <timer name="rtc" tickpolicy="catchup"/>
          <timer name="pit" tickpolicy="delay"/>
          <timer name="hpet" present="no"/>
        </clock>
        <on_poweroff>destroy</on_poweroff>
        <on_reboot>restart</on_reboot>
        <on_crash>destroy</on_crash>
        <pm>
          <suspend-to-mem enabled="no"/>
          <suspend-to-disk enabled="no"/>
        </pm>
        <devices>
          <emulator>/run/libvirt/nix-emulators/qemu-system-x86_64</emulator>
          <disk type="block" device="disk">
            <driver name="qemu" type="raw" discard="unmap"/>
            <source dev="/dev/zvol/r/varlib/vm/josh-pc/system"/>
            <target dev="sda" bus="scsi"/>
            <boot order="1"/>
            <address type="drive" controller="0" bus="0" target="0" unit="0"/>
          </disk>
          <disk type="block" device="disk">
            <driver name="qemu" type="raw" discard="unmap"/>
            <source dev="/dev/zvol/r/varlib/vm/josh-pc/data"/>
            <target dev="sdb" bus="scsi"/>
            <address type="drive" controller="0" bus="0" target="0" unit="1"/>
          </disk>
          <controller type="scsi" index="0" model="virtio-scsi"/>
          <interface type="direct">
            <mac address="52:54:00:6e:b4:bc"/>
            <source dev="enp8s0" mode="bridge"/>
            <model type="virtio"/>
          </interface>
          <interface type="network">
            <mac address="d4:7b:31:69:c4:1d"/>
            <source network="local"/>
            <model type="virtio"/>
          </interface>
          <tpm model="tpm-tis">
            <backend type="emulator" version="2.0"/>
          </tpm>
          <rng model="virtio">
            <backend model="random">/dev/urandom</backend>
          </rng>
          <panic model="hyperv"/>
          <memballoon model="virtio"/>
          <controller type="virtio-serial" index="0"/>
          <channel type='unix'>
            <target type='virtio' name='org.qemu.guest_agent.0'/>
            <address type='virtio-serial' controller='0' bus='0' port='1'/>
          </channel>
          <!-- -->
          <video>
            <model type="qxl" ram="65536" vram="65536" vgamem="16384" heads="1" primary="yes"/>
          </video>
          <!-- -->
          <!--
          <graphics type="spice" autoport="yes">
            <listen type="address"/>
          </graphics>
          <channel type="spicevmc">
            <target type="virtio" name="com.redhat.spice.0"/>
            <address type="virtio-serial" controller="0" bus="0" port="2"/>
          </channel>
          <redirdev bus="usb" type="spicevmc"/>
          -->
          <!--
          <input type="tablet" bus="usb"/>
          <input type="mouse" bus="ps2"/>
          <input type="keyboard" bus="ps2"/>
          <sound model="ich6"/>
          <audio id="1" type="spice"/>
          -->
          <hostdev mode="subsystem" type="pci" managed="yes">
            <driver name="vfio"/>
            <source>
              <address domain="0x0000" bus="0x65" slot="0x00" function="0x0"/>
            </source>
            <address type="pci" domain="0x0000" bus="0x07" slot="0x00" function="0x0"/>
          </hostdev>
          <hostdev mode="subsystem" type="pci" managed="yes">
            <driver name="vfio"/>
            <source>
              <address domain="0x0000" bus="0x65" slot="0x00" function="0x1"/>
            </source>
            <address type="pci" domain="0x0000" bus="0x07" slot="0x00" function="0x1"/>
          </hostdev>
          <hostdev mode="subsystem" type="pci" managed="yes">
            <driver name="vfio"/>
            <source>
              <address domain="0x0000" bus="0xb3" slot="0x00" function="0x0"/>
            </source>
          </hostdev>
          <hostdev mode="subsystem" type="pci" managed="yes">
            <driver name="vfio"/>
            <source>
              <address domain="0x0000" bus="0x00" slot="0x17" function="0x0"/>
            </source>
          </hostdev>
        </devices>
      </domain>
    '';
    "vm/local-net.xml".text = ''
      <network>
        <name>local</name>
        <domain name="local"/>
        <ip address="192.168.100.1" netmask="255.255.255.0">
          <dhcp>
            <range start="192.168.100.128" end="192.168.100.254"/>
            <host mac="d4:7b:31:69:c4:1d" name="josh-pc" ip="192.168.100.2"/>
          </dhcp>
        </ip>
      </network>
    '';
    "vm/josh-pc/startpre.sh" = {
      text = ''
        #! /usr/bin/env bash
        COUNT=0
        while [ $COUNT -le 10 ]
        do
          ((COUNT++))
          ${pkgs.libvirt}/bin/virsh connect 2>/dev/null
          [ $? -eq 0 ] && exit 0 || sleep 1
        done
        exit 1
      '';
      mode = "0555";
    };
    "vm/josh-pc/start.sh" = {
      text = ''
        #! /usr/bin/env bash
        ${pkgs.libvirt}/bin/virsh net-info local >/dev/null 2>&1 || ${pkgs.libvirt}/bin/virsh net-create /etc/vm/local-net.xml
        ${pkgs.zfs}/bin/zfs list r/varlib/vm/josh-pc >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create r/varlib/vm/josh-pc
        ${pkgs.zfs}/bin/zfs list r/varlib/vm/josh-pc/system >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create -b 8k -s -V 512G r/varlib/vm/josh-pc/system
        ${pkgs.zfs}/bin/zfs list r/varlib/vm/josh-pc/data >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create -b 8k -s -V 2048G r/varlib/vm/josh-pc/data
        ${pkgs.libvirt}/bin/virsh destroy josh-pc || true
        ${pkgs.libvirt}/bin/virsh create /etc/vm/josh-pc.xml
        # for x in system.slice user.slice init.scope
        # do
        #   systemctl set-property --runtime -- $x AllowedCPUs=0-1,18-19
        # done
      '';
      mode = "0555";
    };
    "vm/josh-pc/stop.sh" = {
      text = ''
        #! /usr/bin/env bash
        # for x in system.slice user.slice init.scope
        # do
        #   systemctl set-property --runtime -- $x AllowedCPUs=0-35
        # done
        export LANG=C
        COUNT=0
        while [ $COUNT -le 60 ]
        do
          STATE=$(${pkgs.libvirt}/bin/virsh domstate josh-pc 2>&1)
          if [[ "$STATE" == "shut off" ]] || [[ "''${STATE::27}" == "error: failed to get domain" ]]
          then
            exit 0
          fi
          if [[ "$STATE" == "running" ]]
          then
            [ $(($COUNT % 15)) -eq 0 ] && ${pkgs.libvirt}/bin/virsh shutdown josh-pc --mode agent
            ((COUNT++))
          fi
          sleep 1
        done
        exit 1
      '';
      mode = "0555";
    };
  };

  systemd = {
    services = {
      vm-josh-pc = {
        enable = true;
        description = "Virtual Machine Josh-PC";
        wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        path = with pkgs; [ bash libvirt zfs ];
        environment = {
          DOMAIN_DIR = "/etc/libvirt/qemu";
          DOMAIN = "josh-pc";
        };
        serviceConfig = {
          Type = "forking";
          PIDFile = "/run/libvirt/qemu/josh-pc.pid";

          # Check if libvirtd is responsive by connecting to it. This is not allowed to fail.
          ExecStartPre = "${pkgs.bash}/bin/bash -c /etc/vm/josh-pc/startpre.sh";
          # Create the domain.
          ExecStart = "${pkgs.bash}/bin/bash -c /etc/vm/josh-pc/start.sh";
          # Shutdown the domain gracefully by sending ACPI shutdown event.
          ExecStop = "${pkgs.bash}/bin/bash -c /etc/vm/josh-pc/stop.sh";
          # Set higher timeouts to allow for Exec commands to take longer.
          TimeoutStartSec = 90;
          TimeoutStopSec = 180;
        };
      };
    };
  };
}
