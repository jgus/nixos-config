{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShellNoCC {
  buildInputs = with pkgs; [
    (writeScriptBin "nixos-deploy-all" (builtins.readFile ./bin/nixos-deploy-all.sh))
    (writeScriptBin "verify-sops-backups" (builtins.readFile ./bin/verify-sops-backups.sh))
    (writeScriptBin "test-all" (builtins.readFile ./test/test.sh))
    git
    sops
    age
    nixos-rebuild
  ];

  shellHook = ''
  '';
}
