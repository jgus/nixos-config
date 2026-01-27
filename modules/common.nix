with builtins;
{ config, lib, machine, options, pkgs, ... }:
{
  boot = {
    tmp.useTmpfs = true;
    supportedFilesystems = [ "ntfs" ];
  };

  zramSwap.enable = true;

  time.timeZone = machine.timeZone;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search nixpkgs wget
  environment = {
    systemPackages = with pkgs; [
      clang-tools # TODO
      nixd
      nixpkgs-fmt
    ];
    variables = {
      SERVER_NAMES = concatStringsSep " " lib.homelab.serverNames;
      OTHER_SERVER_NAMES = concatStringsSep " " (lib.lists.remove machine.hostName lib.homelab.serverNames);
    };
  };

  nixpkgs.config.allowUnfree = true;

  services = {
    davfs2.enable = true;

    openssh = {
      enable = true;
      openFirewall = true;
      extraConfig = ''
        AllowAgentForwarding yes
      '';
      # Use backup-ssh.sh and restore-ssh.sh to backup/restore keys
      hostKeys = [
        { path = "/etc/ssh/ssh_host_ed25519_key"; type = "ed25519"; }
        { path = "/etc/ssh/ssh_host_ecdsa_key"; type = "ecdsa"; }
        { path = "/etc/ssh/ssh_host_rsa_key"; type = "rsa"; bits = 4096; }
      ];
    };

    fwupd.enable = machine.fwupd;
  };

  programs = {
    command-not-found.enable = false;
    direnv = {
      enable = true;
      silent = true;
    };
    git.enable = true;
    git.lfs.enable = true;
    gnupg.agent.enable = true;
    htop.enable = true;
    mosh.enable = true;
    nix-index.enable = true;
    nix-index-database.comma.enable = true;
    nix-ld = {
      enable = true;
      libraries = options.programs.nix-ld.libraries.default ++ (
        with pkgs; [
          glib # libglib-2.0.so.0, libgthread-2.0.so.0
        ]
      );
    };
    ssh.startAgent = true;
    tmux.enable = true;
  };

  system = {
    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It's perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    stateVersion = machine.stateVersion; # Did you read the comment?
  };

  nix = {
    gc = {
      automatic = true;
      persistent = true;
      options = "--delete-older-than 3d";
      dates = "weekly";
    };
    extraOptions = ''
      download-buffer-size = ${toString (512*1024*1024)}
      experimental-features = nix-command flakes
    '';
    settings = {
      auto-optimise-store = true;
      substituters = [
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    };
  };

  security.polkit.enable = true;
}
