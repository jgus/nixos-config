{ config, pkgs, lib, ... }:
{
  boot = {
    # Enable binfmt emulation for aarch64 to allow cross-building for Raspberry Pi
    binfmt.emulatedSystems = [ "aarch64-linux" ];
    # kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 5;
    };
  };

  fileSystems."/etc/nixos/.secrets" = {
    device = "/boot/.secrets";
    options = [ "bind" ];
  };

  # Allow building for aarch64 (Raspberry Pi) via binfmt emulation
  # - sandbox = "relaxed": Fall back to unsandboxed when namespaces unavailable (QEMU can't emulate them)
  # - filter-syscalls = false: Disable seccomp filtering (QEMU can't emulate seccomp BPF)
  nix.settings = {
    extra-platforms = [ "aarch64-linux" ];
    sandbox = "relaxed";
    filter-syscalls = false;
  };

  system = {
    autoUpgrade = {
      enable = true;
      allowReboot = true;
    };
    includeBuildDependencies = true;
    activationScripts = {
      syncBoot.text = ''
        i=1
        while mountpoint -q /boot/''${i}
        do
            ${pkgs.rsync}/bin/rsync -arqx --delete /boot/ /boot/''${i}/
            ((i+=1))
        done
      '';
    };
  };
}
