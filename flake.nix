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
    { devshell
    , flake-utils
    , nix-index-database
    , nixos-hardware
    , nixos-extra-modules
    , nixpkgs
    , nixpkgs-unstable
    , sops-nix
    , self
    , ...
    } @ inputs:
    let
      machineIds = [ "b1" "c1-1" "c1-2" "d1" "pi-67cba1" ];

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
          inherit addresses container lib machine testResults;
        };

      mkMachine = machineId:
        let
          specialArgs = mkSpecialArgs machineId;
          machine = specialArgs.machine;
        in
        nixpkgs.lib.nixosSystem {
          inherit (machine) system;
          specialArgs = specialArgs // { inherit inputs; };
          modules = [
            ./modules/assert-test-results.nix
            ./machine/${machine.hostName}/hardware-configuration.nix
            ./modules/common.nix
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
      nixosConfigurations =
        nixpkgs.lib.listToAttrs (map
          (machineId: {
            name = machineId;
            value = mkMachine machineId;
          })
          machineIds);

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
