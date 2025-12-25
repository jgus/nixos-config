# SearXNG MCP Server - Model Context Protocol server for web search integration
# https://github.com/tcpipuk/mcp-server
{ ... }:
{
  configStorage = false;
  docker = {
    image = "ghcr.io/tcpipuk/mcp-server/server:latest";
    environment = {
      SEARXNG_QUERY_URL = "http://searxng:8080";
      SSE_HOST = "::";
      SSE_PORT = "80";
    };
  };
}
