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
      nixosConfigurations =
        let
          machineIds = [ "b1" "c1-1" "c1-2" "d1" "pi-67cba1" ];

          mkMachine = machineId:
            let
              machine = import ./settings/machine.nix { inherit machineId; lib = nixpkgs.lib; };
              myLib = import ./my-lib.nix {
                lib = nixpkgs.lib;
                pkgs = nixpkgs.legacyPackages.${machine.system};
              };
              addresses = import ./settings/addresses.nix {
                lib = nixpkgs.lib;
                inherit myLib;
              };
              container = import ./settings/container.nix {
                inherit machine addresses;
                pkgs = nixpkgs.legacyPackages.${machine.system};
                lib = nixpkgs.lib;
              };
            in
            nixpkgs.lib.nixosSystem {
              inherit (machine) system;
              specialArgs = {
                inherit inputs machine addresses container myLib;
              };
              modules = [
                ./machine/${machine.hostName}/hardware-configuration.nix
                ./modules/common.nix
                ./modules/${machine.arch}.nix
                ./modules/host.nix
                ./modules/users.nix
                ./modules/sops.nix
                ./modules/vscode.nix
                ./modules/storage.nix
                ./modules/services.nix
                ./modules/status2mqtt.nix
                ./modules/systemctl-mqtt.nix
                sops-nix.nixosModules.sops
                nix-index-database.nixosModules.nix-index
              ]
              ++ nixpkgs.lib.optional machine.nvidia ./modules/nvidia.nix
              ++ nixpkgs.lib.optional machine.zfs ./modules/zfs.nix
              ++ nixpkgs.lib.optional machine.clamav ./modules/clamav.nix
              ++ nixpkgs.lib.optional machine.python ./modules/python.nix
              ++ machine.imports;
            };
        in
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
