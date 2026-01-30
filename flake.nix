{
  description = "NixOS flake configuration";

  inputs = {
    # Core inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Hardware inputs
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # NixOS modules
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-extra-modules-src = {
      url = "github:oddlama/nixos-extra-modules";
      flake = false;
    };

    # Dev shell
    devshell.url = "github:numtide/devshell";
    flake-utils.url = "github:numtide/flake-utils";

    bash.url = "path:./flakes/bash";
  };

  outputs =
    { bash
    , nix-index-database
    , nixos-hardware
    , nixos-extra-modules-src
    , nixpkgs
    , sops-nix
    , self
    , ...
    }:
    let
      overlayNetLib = pkgs:
        let
          pkgsLibOverlay = pkgs: lib: pkgs // {
            lib = pkgs.lib // lib;
          };
          # import netu.nix - it's a module with a .lib
          netu = (import (nixos-extra-modules-src + "/lib/netu.nix") { inherit (pkgs) lib; });
          # Create a pkgs-like structure with netu included in lib
          pkgsNetu = pkgsLibOverlay pkgs netu.lib;
          # Import misc.nix - it's an overlay: inputs: final: prev:
          misc = import (nixos-extra-modules-src + "/lib/misc.nix") { inherit nixpkgs; };
          # Create a pkgs-like structure with misc included in lib
          pkgsMisc = pkgsLibOverlay pkgsNetu (misc pkgsNetu pkgsNetu).lib;
          # Import net.nix - it's an overlay: inputs: final: prev:
          net = import (nixos-extra-modules-src + "/lib/net.nix") { inherit nixpkgs; };
          # Create a pkgs-like structure with net included in lib
          netPkgs = pkgsLibOverlay pkgsMisc (net pkgsMisc pkgsMisc).lib;
        in
        netPkgs.lib;

      mkSpecialArgs = machineId:
        let
          machine = import ./settings/machine.nix { inherit machineId; lib = nixpkgs.lib; };
          pkgs = nixpkgs.legacyPackages.${machine.system};
          libNet = overlayNetLib nixpkgs;
          addresses = import ./settings/addresses.nix { lib = libNet; };
          libExt = libNet // (import ./lib-homelab.nix {
            inherit addresses pkgs;
            lib = libNet;
          });
          lib = libExt;
        in
        {
          inherit addresses lib machine nixos-hardware self;
        };

      mkMachine = machineId:
        let
          specialArgs = mkSpecialArgs machineId;
          machine = specialArgs.machine;
        in
        nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          modules = [
            { networking.hostName = machineId; }
            ./settings/container.nix
            ./settings/network.nix
            ./test/tests.nix
            ./machine/${machineId}/hardware-configuration.nix
            ./modules/common.nix
            ./modules/label.nix
            ./modules/network.nix
            ./modules/network-options.nix
            ./modules/sops.nix
            ./modules/users.nix
            ./modules/msmtp.nix
            ./modules/vscode.nix
            ./modules/storage.nix
            ./modules/container.nix
            ./modules/services.nix
            ./modules/status2mqtt.nix
            ./modules/systemctl-mqtt.nix
            sops-nix.nixosModules.sops
            nix-index-database.nixosModules.nix-index
            bash.nixosModules.bash
          ]
          ++ nixpkgs.lib.optional machine.nvidia ./modules/nvidia.nix
          ++ nixpkgs.lib.optional machine.zfs ./modules/zfs.nix
          ++ nixpkgs.lib.optional machine.clamav ./modules/clamav.nix
          ++ machine.imports;
        };
    in
    {
      # NixOS configurations for each machine
      nixosConfigurations = {
        "b1" = mkMachine "b1";
        "c1-1" = mkMachine "c1-1";
        "c1-2" = mkMachine "c1-2";
        "d1" = mkMachine "d1";
        "pi-67cba1" = mkMachine "pi-67cba1";
      };

      # Development shell
      devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShellNoCC {
        buildInputs = with nixpkgs.legacyPackages.x86_64-linux; [
          (writeScriptBin "nixos-deploy-all" ''
            if [ "$(hostname)" = "code-server" ]; then
              ${./bin/nixos-deploy-all-c1-2.sh} "$@"
            else
              ${./bin/nixos-deploy-all.sh} "$@"
            fi
          '')
          (writeScriptBin "verify-sops-backups" ''${./bin/verify-sops-backups.sh} "$@"'')
          (writeScriptBin "update-images" ''${./bin/update-images.sh} "$@"'')
          git
          sops
          age
          nixos-rebuild
        ];

        shellHook = ''
          # echo "devShell activated"
        '';
      };
    };
}
