{ pkgs, ... }:

{
  imports = [ ./libvirt.nix ];

  environment.etc = {
    "vm/vm1.xml".text = ''
      <domain type="kvm">
        <name>vm1</name>
        <uuid>99fefcc4-d5aa-4717-8dde-4fe5f0552d87</uuid>
        <memory unit="GiB">96</memory>
        <currentMemory unit="GiB">96</currentMemory>
        <vcpu placement="static">24</vcpu>
        <iothreads>4</iothreads>
        <cputune>
          <vcpupin vcpu="0" cpuset="12"/>
          <vcpupin vcpu="1" cpuset="36"/>
          <vcpupin vcpu="2" cpuset="13"/>
          <vcpupin vcpu="3" cpuset="37"/>
          <vcpupin vcpu="4" cpuset="14"/>
          <vcpupin vcpu="5" cpuset="38"/>
          <vcpupin vcpu="6" cpuset="15"/>
          <vcpupin vcpu="7" cpuset="39"/>
          <vcpupin vcpu="8" cpuset="16"/>
          <vcpupin vcpu="9" cpuset="40"/>
          <vcpupin vcpu="10" cpuset="17"/>
          <vcpupin vcpu="11" cpuset="41"/>
          <vcpupin vcpu="12" cpuset="18"/>
          <vcpupin vcpu="13" cpuset="42"/>
          <vcpupin vcpu="14" cpuset="19"/>
          <vcpupin vcpu="15" cpuset="43"/>
          <vcpupin vcpu="16" cpuset="20"/>
          <vcpupin vcpu="17" cpuset="44"/>
          <vcpupin vcpu="18" cpuset="21"/>
          <vcpupin vcpu="19" cpuset="45"/>
          <vcpupin vcpu="20" cpuset="22"/>
          <vcpupin vcpu="21" cpuset="46"/>
          <vcpupin vcpu="22" cpuset="23"/>
          <vcpupin vcpu="23" cpuset="47"/>
          <emulatorpin cpuset="0,24"/>
          <iothreadpin iothread="1" cpuset="2,4,26,28"/>
        </cputune>
        <os>
          <type arch="x86_64" machine="q35">hvm</type>
          <loader readonly="yes" secure="yes" type="pflash">/run/libvirt/nix-ovmf/OVMF_CODE.fd</loader>
          <nvram template="/run/libvirt/nix-ovmf/OVMF_VARS.fd">/var/lib/vm/vm1/VARS.fd</nvram>
        </os>
        <features>
          <acpi/>
          <apic/>
          <vmport state="off"/>
          <smm state="on"/>
        </features>
        <cpu mode="host-passthrough">
          <topology sockets="1" cores="12" threads="2"/>
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
            <source dev="/dev/zvol/r/varlib/vm/vm1/system"/>
            <target dev="sda" bus="scsi"/>
            <boot order="1"/>
            <address type="drive" controller="0" bus="0" target="0" unit="0"/>
          </disk>
          <!-- -->
          <disk type="file" device="cdrom">
            <driver name="qemu" type="raw"/>
            <source file="/d/software/MSDN/Windows/Windows 11/Win11_22H2_English_x64v1.iso"/>
            <target dev="sdb" bus="sata"/>
            <readonly/>
            <boot order="2"/>
            <address type="drive" controller="0" bus="0" target="0" unit="1"/>
          </disk>
          <disk type="file" device="cdrom">
            <driver name="qemu" type="raw"/>
            <source file="/d/software/Drivers/virtio-win-0.1.229.iso"/>
            <target dev="sdc" bus="sata"/>
            <readonly/>
            <address type="drive" controller="0" bus="0" target="0" unit="2"/>
          </disk>
          <!-- -->
          <controller type="scsi" index="0" model="virtio-scsi"/>
          <controller type="sata" index="0"/>
          <controller type="virtio-serial" index="0"/>
          <interface type="direct">
            <mac address="52:54:00:6e:b4:bc"/>
            <source dev="enp5s0f1" mode="bridge"/>
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
          <redirdev bus="usb" type="spicevmc"/>
          <memballoon model="virtio"/>
        </devices>
      </domain>
    '';
    "vm/vm1/startpre.sh" = {
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
    "vm/vm1/start.sh" = {
      text = ''
        #! /usr/bin/env bash
        ${pkgs.zfs}/bin/zfs list r/varlib/vm/vm1 >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create r/varlib/vm/vm1
        ${pkgs.zfs}/bin/zfs list r/varlib/vm/vm1/system >/dev/null 2>&1 || ${pkgs.zfs}/bin/zfs create -b 8k -s -V 256G r/varlib/vm/vm1/system
        ${pkgs.libvirt}/bin/virsh create /etc/vm/vm1.xml
        for x in system.slice user.slice init.scope
        do
          systemctl set-property --runtime -- $x AllowedCPUs=0-11,24-35
        done
      '';
      mode = "0555";
    };
    "vm/vm1/stop.sh" = {
      text = ''
        #! /usr/bin/env bash
        for x in system.slice user.slice init.scope
        do
          systemctl set-property --runtime -- $x AllowedCPUs=0-47
        done
        export LANG=C
        COUNT=0
        while [ $COUNT -le 60 ]
        do
          STATE=$(${pkgs.libvirt}/bin/virsh domstate vm1 2>&1)
          if [[ "$STATE" == "shut off" ]] || [[ "''${STATE::27}" == "error: failed to get domain" ]]
          then
            exit 0
          fi
          if [[ "$STATE" == "running" ]]
          then
            [ $(($COUNT % 15)) -eq 0 ] && ${pkgs.libvirt}/bin/virsh shutdown vm1
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
      vm-vm1 = {
        enable = true;
        description = "Virtual Machine vm1";
        # wantedBy = [ "multi-user.target" ];
        requires = [ "network-online.target" ];
        path = with pkgs; [ bash libvirt zfs ];
        environment = {
          DOMAIN_DIR = "/etc/libvirt/qemu";
          DOMAIN = "vm1";
        };
        serviceConfig = {
          Type = "forking";
          PIDFile = "/run/libvirt/qemu/vm1.pid";

          # Check if libvirtd is responsive by connecting to it. This is not allowed to fail.
          ExecStartPre = "${pkgs.bash}/bin/bash -c /etc/vm/vm1/startpre.sh";
          # Create the domain.
          ExecStart = "${pkgs.bash}/bin/bash -c /etc/vm/vm1/start.sh";
          # Shutdown the domain gracefully by sending ACPI shutdown event.
          ExecStop = "${pkgs.bash}/bin/bash -c /etc/vm/vm1/stop.sh";
          # Set higher timeouts to allow for Exec commands to take longer.
          TimeoutStartSec = 90;
          TimeoutStopSec = 180;
        };
      };
    };
  };
}
