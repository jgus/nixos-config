# SearXNG MCP Server - Model Context Protocol server for web search integration
# https://github.com/tcpipuk/mcp-server
{ ... }:
{
  configStorage = false;
  docker = {
    pullImage =
      # nix-shell -p nix-prefetch-docker --run 'nix-prefetch-docker --quiet --image-name ghcr.io/tcpipuk/mcp-server/server --image-tag latest'
      {
        imageName = "ghcr.io/tcpipuk/mcp-server/server";
        imageDigest = "sha256:6388f951cbb6037c001c07504aab9161f981ecbbcda01a3deb2f8e5ba0a14d45";
        hash = "sha256-nctO0We6xN59AJhMguntyuXh6Nl3jeGS7TtJmA7bX/w=";
        finalImageName = "ghcr.io/tcpipuk/mcp-server/server";
        finalImageTag = "latest";
      };
    environment = {
      SEARXNG_QUERY_URL = "http://searxng:8080";
      SSE_HOST = "::";
      SSE_PORT = "80";
    };
  };
}
