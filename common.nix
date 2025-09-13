let
  addresses = import ./addresses.nix;
  machine = import ./machine.nix;
in
{ pkgs, lib, options, ... }:
{
  boot = {
    initrd.secrets."/etc/nixos/.secrets/vkey" = ./.secrets/vkey;
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
    firewall = {
      allowPing = true;
      allowedTCPPorts = [ 5201 ]; # iperf
      allowedUDPPorts = [ 5201 ]; # iperf
    };
    useDHCP = false;
    tempAddresses = "disabled";
    defaultGateway.address = addresses.network.defaultGateway;
    domain = addresses.network.domain;
    nameservers = [ addresses.records.pihole-1.ip addresses.records.pihole-2.ip addresses.records.pihole-3.ip "1.1.1.1" "1.0.0.1" ];
    timeServers = [ "ntp.home.gustafson.me" ];
    hosts = addresses.hosts // addresses.hosts6;
    interfaces.lan0 = let m = addresses.records."${machine.hostName}"; in {
      macAddress = m.mac;
      ipv4.addresses = [{ address = m.ip; prefixLength = addresses.network.prefixLength; }];
      ipv6.addresses = [{ address = m.ip6; prefixLength = addresses.network.prefix6Length; }];
    };
    macvlans.lan0 = {
      interface = machine.lan-interface;
      mode = "bridge";
    };
  } // (if (machine ? lan-interfaces) then {
    bridges."${machine.lan-interface}".interfaces = machine.lan-interfaces;
  } else { });

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment = {
    systemPackages = with pkgs; [
      clang-tools # TODO
      comma
      nixd
      nixpkgs-fmt
    ];
    variables = {
      SERVER_NAMES = builtins.concatStringsSep " " addresses.serverNames;
      OTHER_SERVER_NAMES = builtins.concatStringsSep " " (lib.lists.remove machine.hostName addresses.serverNames);
    };
  };

  services = {
    davfs2.enable = true;

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
    command-not-found.enable = false;
    direnv.enable = true;
    git.enable = true;
    git.lfs.enable = true;
    gnupg.agent.enable = true;
    htop.enable = true;
    mosh.enable = true;
    nix-index.enable = true;
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
      options = "--delete-older-than 3d";
    };
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings = {
      auto-optimise-store = true;
    };
  };

  security.polkit.enable = true;
}
