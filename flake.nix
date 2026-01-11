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

    # Dev shell
    devshell.url = "github:numtide/devshell";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-unstable
    , nixos-hardware
    , sops-nix
    , nix-index-database
    , devshell
    , flake-utils
    , ...
    } @ inputs: {
      # NixOS configurations for each machine
      nixosConfigurations = {
        b1 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            machine = import ./machine.nix { lib = nixpkgs.lib; machineId = "b1"; };
          };
          modules = [
            ./configuration.nix
            ./machine/b1/hardware-configuration.nix
            sops-nix.nixosModules.sops
            nix-index-database.nixosModules.nix-index
          ];
        };

        c1-1 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            machine = import ./machine.nix { lib = nixpkgs.lib; machineId = "c1-1"; };
          };
          modules = [
            ./configuration.nix
            ./machine/c1-1/hardware-configuration.nix
            sops-nix.nixosModules.sops
            nix-index-database.nixosModules.nix-index
          ];
        };

        c1-2 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            machine = import ./machine.nix { lib = nixpkgs.lib; machineId = "c1-2"; };
          };
          modules = [
            ./configuration.nix
            ./machine/c1-2/hardware-configuration.nix
            sops-nix.nixosModules.sops
            nix-index-database.nixosModules.nix-index
          ];
        };

        d1 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs;
            machine = import ./machine.nix { lib = nixpkgs.lib; machineId = "d1"; };
          };
          modules = [
            ./configuration.nix
            ./machine/d1/hardware-configuration.nix
            sops-nix.nixosModules.sops
            nix-index-database.nixosModules.nix-index
          ];
        };

        pi-67cba1 = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = {
            inherit inputs;
            machine = import ./machine.nix { lib = nixpkgs.lib; machineId = "pi-67cba1"; };
          };
          modules = [
            ./configuration.nix
            ./machine/pi-67cba1/hardware-configuration.nix
            sops-nix.nixosModules.sops
            nix-index-database.nixosModules.nix-index
          ];
        };
      };

      # Development shell
      devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShellNoCC {
        buildInputs = with nixpkgs.legacyPackages.x86_64-linux; [
          (writeScriptBin "nixos-deploy-all" (builtins.readFile ./bin/nixos-deploy-all.sh))
          (writeScriptBin "verify-sops-backups" (builtins.readFile ./bin/verify-sops-backups.sh))
          git
          sops
          age
        ];
      };
    };
}
