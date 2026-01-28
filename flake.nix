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
    nixos-extra-modules = {
      url = "github:oddlama/nixos-extra-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Dev shell
    devshell.url = "github:numtide/devshell";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nix-index-database
    , nixos-hardware
    , nixos-extra-modules
    , nixpkgs
    , sops-nix
    , self
    , ...
    }:
    let
      mkSpecialArgs = machineId:
        let
          machine = import ./settings/machine.nix { inherit machineId; lib = nixpkgs.lib; };
          pkgs = import nixpkgs { inherit (machine) system; };
          libNet = (import nixpkgs {
            inherit (machine) system;
            overlays = [ nixos-extra-modules.overlays.default ];
          }).lib;
          addresses = import ./settings/addresses.nix { lib = libNet; };
          container = import ./settings/container.nix { inherit pkgs; };
          libExt = libNet // (import ./lib-homelab.nix {
            inherit addresses pkgs;
            lib = libNet;
          });
          lib = libExt;
          testResults = import ./test/lib-homelab-test.nix { inherit lib; };
        in
        {
          inherit addresses container lib machine nixos-hardware self testResults;
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
            ./modules/assert-test-results.nix
            ./machine/${machineId}/hardware-configuration.nix
            ./modules/common.nix
            ./modules/label.nix
            ./modules/network.nix
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
          (writeScriptBin "verify-sops-backups" (builtins.readFile ./bin/verify-sops-backups.sh))
          (writeScriptBin "update-images" (builtins.readFile ./bin/update-images.sh))
          git
          sops
          age
          nixos-rebuild
        ];

        shellHook = ''
          echo "Using default devShell"
        '';
      };
    };
}
