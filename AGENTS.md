# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## NixOS Home Lab Architecture

- This is a **multi-machine NixOS configuration** managing 5 physical servers (b1, c1-1, c1-2, d1, pi-67cba1)
- All configurations are declarative Nix expressions
- Services are defined in `addresses.nix` and instantiated on specific host machines

## Critical Project-Specific Patterns

### Service Management

- **Service location**: Determined by `addresses.nix` - each service record has a `host` attribute
- **MACHINE_ID required**: Set environment variable `MACHINE_ID` when building configurations:
  ```bash
  MACHINE_ID="c1-2" nix-build '<nixpkgs/nixos>' -A config.system.build.toplevel
  ```
- **Cross-machine deployment**: Use `./bin/nixos-deploy-all.sh` to build/test/switch all machines
- **Service types**: Each service is EITHER docker-based OR systemd-based, never both

### Networking

- **Macvlan networking**: Used for services that need direct network access with unique MAC addresses
- **IPv6 EUI-64**: Automatically generated from MAC addresses in `addresses.nix`
- **Routing tables**: Custom routing tables (1000+) used for macvlan services

### Storage

- **ZFS integration**: Storage paths created as ZFS datasets when available
- **Automatic backups**: All service storage is backed up hourly via rsync
- **Backup paths**: `/service/<name>` backed up to `/storage/service/<name>`
- **Extra storage**: Declared via `extraStorage` attribute in service definitions

### Service Definition Requirements

- **Requires mount points**: Many services require mount points (e.g., "storage-media.mount")
- **Config storage**: Defaults to `true` unless explicitly set to `false`
- **Backup mechanism**: Built-in automatic backup system for all service storage

## Deployment Commands

For your information, but NOT FOR AGENT USE

```bash
# Build and test all configurations
./bin/nixos-deploy-all.sh

# Build, test, and switch all configurations
./bin/nixos-deploy-all.sh --switch
```

## Cross-Server Operations

For your information, but NOT FOR AGENT USE

- `./bin/on-all-servers.sh` - Run commands on all machines in parallel
- Services must declare their dependencies via the `requires` attribute

## Non-Obvious Code Patterns

1. **Dynamic MAC address generation**: MAC addresses auto-generated from group/ID in `addresses.nix`
2. **Docker options**: All docker services use macvlan with specific IP/MAC assignment
3. **Service discovery**: `addresses.nix` is the source of truth for service-to-host mapping
4. **ZFS snapshot management**: Custom scripts in `bin/functions.sh` for snapshot operations
5. **Cross-machine deployments**: Cross-machine builds are cached via GC roots in `/etc/nixos/gcroots/`

## CLI Rules

- NEVER run `nix-env -i` or install packages globally
- Use `nix-shell -p <pkg>` for ephemeral tool access
- MACHINE_ID environment variable required for building machine-specific configurations (other than the current machine)
