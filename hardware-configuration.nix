# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "ehci_pci" "megaraid_sas" "usbhid" "usb_storage" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "rpool";
      fsType = "zfs"; options = [ "zfsutil" ];
    };

  fileSystems."/etc/nixos" =
    { device = "rpool/nixos";
      fsType = "zfs"; options = [ "zfsutil" ];
    };

  fileSystems."/home" =
    { device = "rpool/home";
      fsType = "zfs"; options = [ "zfsutil" ];
    };

  fileSystems."/root" =
    { device = "rpool/home/root";
      fsType = "zfs"; options = [ "zfsutil" ];
    };

  fileSystems."/nix" =
    { device = "n/nix";
      fsType = "zfs"; options = [ "zfsutil" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/E068-AA67";
      fsType = "vfat";
    };

  # swapDevices =
  #   [ { device = "/dev/disk/by-uuid/5f576d3a-e8a4-4f0b-acab-082f7bd47022"; priority = 0; }
  #     { device = "/dev/disk/by-uuid/7d6b2f30-c149-4b05-9aa7-b2c93b1d9159"; priority = 0; }
  #     { device = "/dev/disk/by-uuid/eefac7f7-4315-4ed9-b119-b6dd120b10b4"; priority = 0; }
  #     { device = "/dev/disk/by-uuid/2e60f1d1-fac0-4d23-8a89-92f821466487"; priority = 0; }
  #     { device = "/dev/disk/by-uuid/6b6cb073-cd82-4a54-8bd5-e7ad419a16a2"; priority = 0; }
  #     { device = "/dev/disk/by-uuid/68568fc8-60b3-4ba9-9a8b-78f5628e6fd8"; priority = 0; }
  #     { device = "/dev/disk/by-uuid/80e0e3cf-f9c0-472a-ac59-2448d4680159"; priority = 0; }
  #     { device = "/dev/disk/by-uuid/49fa5336-bb07-4a22-b672-e96a679cfbd9"; priority = 0; }
  #     { device = "/dev/disk/by-uuid/3a365c82-ac4e-4ca7-8c60-554c6c473f59"; priority = 0; }
  #     { device = "/dev/disk/by-uuid/6c1d184a-6bf5-4b55-9e2e-a4d207791ce6"; priority = 0; }
  #     { device = "/dev/disk/by-uuid/ab1c3d8e-3b44-43b5-a0a2-2e40f2de0d88"; priority = 0; }
  #     { device = "/dev/disk/by-uuid/5cef981f-b00b-4367-a6da-ad80663b9b56"; priority = 0; }
  #     { device = "/dev/disk/by-uuid/6d983cca-b834-4e39-83a7-ddcf97bb9a83"; priority = 0; }
  #     { device = "/dev/disk/by-uuid/ece99e43-4302-41d9-be83-b86213e9b7ce"; priority = 0; }
  #     { device = "/dev/disk/by-uuid/28269cce-a0b8-4f6c-8e88-818cf518c1c3"; priority = 0; }
  #     { device = "/dev/disk/by-uuid/f705cf0b-9c9e-4d05-9f28-1dbeffc56c73"; priority = 0; }
  #     { device = "/dev/disk/by-uuid/0e67de4c-4a12-4996-a526-852e5ef6c83e"; priority = 0; }
  #     { device = "/dev/disk/by-uuid/3cd13226-7c8a-4df6-8e3b-d2c5d0628914"; priority = 0; }
  #     { device = "/dev/disk/by-uuid/cfe00a4f-d75f-4bfc-ac68-8742258c0e7c"; priority = 0; }
  #     { device = "/dev/disk/by-uuid/5ac01878-1429-47a9-957b-6cb3e9a750dd"; priority = 0; }
  #   ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp2s0f0.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp2s0f1.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp2s0f2.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp2s0f3.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp4s0f0.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp4s0f1.useDHCP = lib.mkDefault true;

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
