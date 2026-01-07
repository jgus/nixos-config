{ pkgs ? import <nixpkgs> { } }:
let
  pw = import ./.secrets/passwords.nix;
in
pkgs.mkShellNoCC {
  buildInputs = with pkgs; [
    aider-chat-full
    (writeScriptBin "nixos-deploy-all" (builtins.readFile ./bin/nixos-deploy-all.sh))
  ];

  OPENAI_API_BASE = "https://nano-gpt.com/api/v1";
  OPENAI_API_KEY = pw.nanoGpt.apiKey;

  shellHook = ''
    echo "🎉 Welcome to the nixos-config project."
  '';
}
