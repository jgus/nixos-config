# SearXNG MCP Server - Model Context Protocol server for web search integration
# https://github.com/ihor-sokoliuk/mcp-searxng
{ ... }:
{
  configStorage = false;
  docker = {
    image = "isokoliuk/mcp-searxng:latest";
    environment = {
      SEARXNG_URL = "http://searxng:8080";
      MCP_HTTP_PORT = "80";
    };
  };
}
