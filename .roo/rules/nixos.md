## NixOS ##

You are running on nixos, a declarative OS. This means:
- If you need to run a command that isn't available, you MAY run `nix-shell -p <pkg> '<cmd> ...'` to run the tool in an ephemeral shell.
- NEVER attempt to install any software globally.
- NEVER attempt to run `nix-env`.
- NEVER run `nixos-rebuild test`, `nixos-rebuild boot`, or `nixos-rebuild switch`
- You MAY run`nixos-rebuild build`
- We use flakes, so don't forget e.g. `--flake .` to build the local machine
