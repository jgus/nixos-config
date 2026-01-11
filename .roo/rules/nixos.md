You are running on nixos, a declarative OS. This means
- If you need to run a command that isn't available, you MAY run `nix-shell -p <pkg> '<cmd> ...'` to run the tool in an ephemeral shell.
- NEVER attempt to install any software globally.
- NEVER attempt to run `nix-env`.
