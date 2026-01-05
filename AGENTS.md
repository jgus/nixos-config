- You are on nixos. Never try to install software globally. If you need to run a piece of software which is not installed, you may do so in an ephemeral shell with `nix-shell -p`.
- Remember to use `-l --no-pager` whenever calling systemctl tools (like journalctl)
- If you need to make a script, use the nix-shell shebang:
#! /usr/bin/env nix-shell
#! nix-shell -i bash -p <package1> <package2> ...
...in order to pull in any dependencies you might need
