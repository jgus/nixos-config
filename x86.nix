{ config, pkgs, ... }:

{
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 1;
    };
  };

  system.activationScripts = {
    syncBoot.text = ''
      i=1
      while mountpoint -q /boot/''${i}
      do
          ${pkgs.rsync}/bin/rsync -arqx --delete /boot/ /boot/''${i}/
          ((i+=1))
      done
    '';
  };
}
