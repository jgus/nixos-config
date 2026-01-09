#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nodejs_24 ripgrep --quiet

# Ensure npx doesn't print update check messages to stdout
export NO_UPDATE_NOTIFIER=true

# Use exec to replace the shell process with the MCP server
# The --quiet flag on npx prevents it from printing "Need to install..."
exec npx --yes --quiet mcp-ripgrep@latest