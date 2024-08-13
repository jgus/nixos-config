{ config, pkgs, ... }:

let
  addresses = import ./addresses.nix;
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
    useDHCP = false;
    tempAddresses = "disabled";
    defaultGateway.address = addresses.network.defaultGateway;
    domain = addresses.network.domain;
    nameservers = [ addresses.services.pihole.ip "1.1.1.1" "1.0.0.1" ];
    timeServers = [ "ntp.home.gustafson.me" ];
    hosts = addresses.hosts;
    interfaces.lan0 = let m = addresses.machines."${machine.hostName}"; in {
      macAddress = m.mac;
      ipv4.addresses = [ { address = m.ip; prefixLength = addresses.network.prefixLength; } ];
    };
    macvlans.lan0 = {
      interface = machine.lan-interface;
      mode = "bridge";
    };
  } // (if (machine ? lan-interfaces) then {
    bridges."${machine.lan-interface}".interfaces = machine.lan-interfaces;
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
