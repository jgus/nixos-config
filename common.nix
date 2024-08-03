{ config, pkgs, ... }:

let
  machine = import ./machine.nix;
in
{
  boot = {
    tmp.useTmpfs = true;
    supportedFilesystems = [ "ntfs" ];
  };

  zramSwap.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  networking = {
    firewall.allowPing = true;

    # The global useDHCP flag is deprecated, therefore explicitly set to false here.
    # Per-interface useDHCP will be mandatory in the future, so this generated config
    # replicates the default behaviour.
    useDHCP = false;
    tempAddresses = "disabled";

    timeServers = [ "ntp.home.gustafson.me" "pool.ntp.org" ];
  } // (if (machine ? bridge) then {
    bridges.br0.interfaces = machine.bridge.interfaces;
    interfaces.br0.macAddress = machine.bridge.mac;
    interfaces.br0.useDHCP = true;
  } else {});

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    parted
    clang-tools # TODO
    nixpkgs-fmt
  ];

  services = {
    ntp.enable = true;

    openssh = {
      enable = true;
      openFirewall = true;
      extraConfig = ''
        AllowAgentForwarding yes
      '';
    };

    fwupd.enable = machine.fwupd;
  };

  programs = {
    command-not-found.enable = true;
    direnv.enable = true;
    git.enable = true;
    git.lfs.enable = true;
    htop.enable = true;
    mosh.enable = true;
    ssh.startAgent = true;
    tmux.enable = true;
  };

  system = {
    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It‘s perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    stateVersion = machine.stateVersion; # Did you read the comment?
  };

  nix = {
    gc = {
      automatic = true;
      persistent = true;
      options = "--delete-older-than 30d";
    };
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  security.polkit.enable = true;
}
