{ pkgs, lib, options, ... }:
let
  addresses = import ./addresses.nix { inherit lib; };
  machine = import ./machine.nix;
  pw = import ./.secrets/passwords.nix;
  hostRecord = addresses.records."${machine.hostName}";
  nixIndexDatabase = builtins.fetchTarball {
    url = "https://github.com/nix-community/nix-index-database/archive/main.tar.gz";
  };
in
{
  imports = [
    "${nixIndexDatabase}/nixos-module.nix"
  ];

  boot = {
    initrd.secrets."/etc/nixos/.secrets/vkey" = ./.secrets/vkey;
    tmp.useTmpfs = true;
    supportedFilesystems = [ "ntfs" ];
    # Fix ARP flux: only respond to ARP when target IP is on the receiving interface
    # This is required for macvlan interfaces to work properly when host has multiple IPs in same subnet
    kernel.sysctl = {
      "net.ipv4.conf.all.arp_ignore" = 1; # Only respond if target IP is local address on receiving interface
      "net.ipv4.conf.all.arp_announce" = 2; # Use best local address for ARP requests
      "net.ipv4.conf.default.arp_ignore" = 1;
      "net.ipv4.conf.default.arp_announce" = 2;
    };
  };

  zramSwap.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Use systemd-networkd for network configuration
  # This provides native support for routing policy rules without oneshot service hacks
  networking = {
    useNetworkd = true;
    firewall = {
      allowPing = true;
      allowedTCPPorts = [ 5201 ]; # iperf
      allowedUDPPorts = [ 5201 ]; # iperf
    };
    useDHCP = false;
    tempAddresses = "disabled";
    domain = addresses.network.domain;
    nameservers = [ addresses.records.pihole-1.ip addresses.records.pihole-2.ip addresses.records.pihole-3.ip "1.1.1.1" "1.0.0.1" ];
    timeServers = [ "ntp.home.gustafson.me" ];
    hosts = addresses.hosts // addresses.hosts6;
  };

  # systemd-networkd configuration
  systemd.network = lib.recursiveUpdate
    {
      enable = true;

      # Create the lan0 macvlan device on the effective LAN interface
      netdevs."10-lan0" = {
        netdevConfig = {
          Kind = "macvlan";
          Name = "lan0";
          MACAddress = hostRecord.mac;
        };
        macvlanConfig = {
          Mode = "bridge";
        };
      };

      # Configure the effective LAN interface (physical or bridge) to be the parent for macvlans
      networks."05-${machine.lan-interface}" = {
        matchConfig.Name = machine.lan-interface;
        networkConfig = {
          # Don't configure IP on this interface - only on macvlans
          LinkLocalAddressing = "no";
          DHCP = "no";
        };
        linkConfig.RequiredForOnline = "carrier";
        # Attach the lan0 macvlan
        macvlan = [ "lan0" ];
      };

      # Configure the lan0 macvlan interface (host's main interface)
      networks."20-lan0" = {
        matchConfig.Name = "lan0";
        networkConfig = {
          DHCP = "no";
          IPv6AcceptRA = "yes";
          LinkLocalAddressing = "ipv6";
        };
        linkConfig.RequiredForOnline = "routable";
        address = [
          "${hostRecord.ip}/${toString addresses.network.prefixLength}"
          "${hostRecord.ip6}/${toString addresses.network.prefix6Length}"
        ];
        gateway = [ addresses.network.defaultGateway ];
        # Routes in main table
        routes = [
          {
            Destination = "${addresses.network.prefix}0.0/${toString addresses.network.prefixLength}";
            Metric = 100;
          }
          {
            Destination = "${addresses.network.prefix6}/${toString addresses.network.prefix6Length}";
            Metric = 100;
          }
          # Routes in lan0 routing table (200) for source-based policy routing
          {
            Destination = "${addresses.network.prefix}0.0/${toString addresses.network.prefixLength}";
            Table = 200;
          }
          {
            Destination = "0.0.0.0/0";
            Gateway = addresses.network.defaultGateway;
            Table = 200;
          }
          {
            Destination = "${addresses.network.prefix6}/${toString addresses.network.prefix6Length}";
            Table = 200;
          }
        ];
        # Source-based policy routing rules - declarative, no oneshot service needed!
        routingPolicyRules = [
          {
            # Traffic FROM this host's IP uses the lan0 routing table
            From = hostRecord.ip;
            Table = 200;
            Priority = 100;
          }
          {
            # IPv6 rule
            From = hostRecord.ip6;
            Table = 200;
            Priority = 100;
          }
        ];
      };
    }
    (if (machine ? lan-interfaces) then {
      # Bridge configuration for multi-interface machines
      # Create the br0 bridge device
      netdevs."00-br0" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "br0";
        };
      };

      # Configure each member interface to join the bridge
      networks."01-bridge-members" = {
        matchConfig.Name = lib.concatStringsSep " " machine.lan-interfaces;
        networkConfig = {
          Bridge = "br0";
          LinkLocalAddressing = "no";
        };
        linkConfig.RequiredForOnline = "enslaved";
      };
    } else { });

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  nixpkgs.config.allowUnfree = true;
  environment = {
    systemPackages = with pkgs; [
      clang-tools # TODO
      nixd
      nixpkgs-fmt
      plandex
    ];
    variables = {
      SERVER_NAMES = builtins.concatStringsSep " " addresses.serverNames;
      OTHER_SERVER_NAMES = builtins.concatStringsSep " " (lib.lists.remove machine.hostName addresses.serverNames);
      NANOGPT_API_KEY = pw.plandex.nanoGptApiKey;
    };
    shellAliases = {
      plandex = "plandex-cli";
      pdx = "plandex-cli";
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
    };
    extraOptions = ''
      download-buffer-size = ${toString (512*1024*1024)}
      experimental-features = nix-command flakes
    '';
    settings = {
      auto-optimise-store = true;
    };
  };

  security.polkit.enable = true;
}
