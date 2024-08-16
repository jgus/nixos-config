{ config, pkgs, ... }:

{
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 1;
    };
  };

  fileSystems."/etc/nixos/.secrets" = {
    device = "/boot/.secrets";
    options = [ "bind" ];
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
