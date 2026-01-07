{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShellNoCC {
  buildInputs = with pkgs; [
    (writeScriptBin "nixos-deploy-all" (builtins.readFile ./bin/nixos-deploy-all.sh))
  ];

  shellHook = ''
    echo "🎉 Welcome to the nixos-config project."
  '';
}
