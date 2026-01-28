{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShellNoCC {
  buildInputs = with pkgs; [
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
    echo "Using shell.nix"
  '';
}
