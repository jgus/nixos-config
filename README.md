# NixOS Home Lab Configuration

A declarative, reproducible NixOS configuration for managing a home lab environment with multiple servers, services, and home automation.

## Overview

This repository contains NixOS configurations for managing a home lab infrastructure with:
- Multiple physical servers (x86_64 and ARM/RPi)
- ZFS storage pools
- Container-based service deployment
- Home automation integration
- Media server capabilities
- Network services and monitoring

## Architecture

### Servers

The configuration manages multiple machines:

- **b1**:  (x86_64) Low-power Beelink x86 box in the network rack. Primarily used for home automation
- **c1-1**: (x86_64) Cisco storage server, node 1. Has the bulk of attached storage. Primarily used for NAS and related services.
- **c1-2**: (x86_64) Cisco storage server, node 2. Used for miscellanious services. (x86_64)
- **d1**: (x86_64) Dell R730xd with lots of RAM & NVIDIA GPUs. Used for media & AI (x86_64)
- **pi-67cba1**: (ARM) Raspberry Pi for home theater control

### Network Structure

See `settings/addresses.nix` for source of truth

- **Network prefix**: `172.22.0.0/16`
- **IPv6 prefix**: `2001:55d:b00b:1::/64`
- **Domain**: `home.gustafson.me`
- **DHCP/DNS**: Provided by Pi-hole instances on multiple servers

## Key Features

### Declarative Configuration
- All configurations defined in Nix expressions
- Machine-specific configurations in `settings/machine.nix`
- Service configurations in `services/` directory

### Service Management
- **Container-based deployment**: Most services run in containers
- **macvlan networking**: Each service gets its own MAC address and IP
- **Automatic backups**: Service data is backed up automatically
- **Storage management**: ZFS integration for snapshots and backups

### Deployment Workflow
The project provides a script for managing cross-machine deployments:

```bash
# Build and test all configurations on all machines
./bin/nixos-deploy-all.sh

# Build, test, and switch all configurations on all machines
./bin/nixos-deploy-all.sh --switch
```

### Address Management
- Centralized address management in `settings/addresses.nix`
- Automatic MAC address generation
- IPv6 support with EUI-64 identifiers
- DNS and DHCP reservations
- Service definitions in `settings/addresses.nix` determine which phyiscal machine instatiates the service

## Directory Structure

```
.
├── flake.nix                # Configuration entry point
├── machine/                 # Machine-specific configurations
│   ├── b1/
│   ├── c1-1/
│   ├── c1-2/
│   ├── d1/
│   └── pi-67cba1/
├── settings/                # Configuration settings
│   ├── machine.nix          # Machine definitions
│   ├── addresses.nix        # Network addressing
│   └── container.nix        # Container configuration
├── modules/                 # NixOS modules
│   ├── cec.nix              # CEC support (RPi)
│   ├── clamav.nix           # ClamAV antivirus
│   ├── common.nix           # Common configuration
│   ├── host.nix             # Host configuration
│   ├── image-update-check.nix  # Container image updates
│   ├── msmtp.nix            # Email sending
│   ├── nebula-sync.nix      # Nebula DNS sync
│   ├── nvidia.nix           # NVIDIA GPU support
│   ├── python.nix           # Python development
│   ├── rpi.nix              # Raspberry Pi specific
│   ├── services.nix         # Service orchestration
│   ├── sops.nix             # SOPS secrets management
│   ├── status2mqtt.nix      # Status to MQTT bridge
│   ├── storage.nix          # Storage configuration
│   ├── systemctl-mqtt.nix   # Systemctl to MQTT bridge
│   ├── ups.nix              # UPS monitoring
│   ├── users.nix            # User configuration
│   ├── vscode.nix           # VSCode remote server
│   ├── x86.nix              # x86 specific
│   ├── zfs.nix              # ZFS filesystem
│   └── ...
├── services/                # Individual service configurations
│   ├── home-assistant.nix
│   ├── jellyfin.nix
│   ├── pihole.nix
│   └── ...
├── images/                   # Container image definitions
├── bin/                      # Various scripts
│   ├── nixos-deploy-all.sh
│   └── ...
├── install/                  # Installation scripts
├── secrets/                  # Encrypted secrets (SOPS)
├── pubkeys/                  # Public keys
└── ...
```

## Usage

### Adding a New Service

1. Create a new Nix file in `services/` (e.g., `services/my-service.nix`)
2. Add a service entry in `settings/addresses.nix`; be sure to assign an id unique within the services group
3. The machine defined as the host of the service in `settings/addresses.nix` will instantiate the service when its configuration is built and applied

### Service Options

Each service definition file (`services/foo.nix`) contains either a single service definition record, or an array of them (to define multiple related services in one file.)

Each service definition record has the following possible attributes:

#### Common Options (for all services)
- **`name`**: The service name (default: based on file name)
- **`user`**: Service user (default: "root")
- **`group`**: Service group (default: "root")
- **`configStorage`**: Enable configuration storage (default: true)
- **`extraStorage`**: Additional storage paths or configurations (e.g., filesystem mounts for systemd services)
- **`requires`**: Service dependencies (systemd units or mount points)
- **`autoStart`**: Whether to start automatically (default: true)
- **`extraConfig`**: Additional Nix configuration (merged into the main config)
- **`container`**: If present, this is a container-based service; see below for details
- **`systemd`**: If present, this is _not_ a container-based service, but a more generic systemd service; see below for details

Note that any given service maybe be _either_ a container service (contains the `container` attribute) _or_ a generic systemd service (contains the `systemd` attribute) but _not_ both. A service _must_ have one or the other.

#### Container Service Options
- **`container.image`**: Container image URI
- **`container.configVolume`**: Container path for config storage
- **`container.volumes`**: Additional volume mounts. Can be either:
  - A list of volume specifications (format: `"host:container[:options]"`)
  - A function that receives the `storagePath` function and returns a list of volume specifications
- **`container.environment`**: Environment variables
- **`container.extraOptions`**: Additional Container CLI options
- **`container.entrypoint`**: Custom container entrypoint
- **`container.entrypointOptions`**: Container command arguments
- **`container.ports`**: Exposed ports. Format is container's format, `"port[:container_port][/protocol]"`
- **`container.dependsOn`**: Container dependencies (other containers this one depends on)
- **`container.environmentFiles`**: Environment files to load

#### Systemd Service Options
- **`systemd.macvlan`**: Use macvlan networking (default: false)
- **`systemd.tcpPorts`**: Open TCP ports
- **`systemd.udpPorts`**: Open UDP ports
- **`systemd.path`**: List of Nix packages to add to PATH (e.g., `[ pkgs.socat pkgs.curl ]`)
- **`systemd.script`**: Service startup script. This is a function that receives a context object containing:
  - `name`: Service name
  - `uid`: User ID
  - `gid`: Group ID
  - `ip`: IPv4 address
  - `ip6`: IPv6 address
  - `interface`: Network interface name (if macvlan enabled)
  - `storagePath`: Function to get storage path for a service
  - `containerOptions`: Additional Container options

### Container Service Examples

#### Simple Container Service

For services running in Container containers:

```nix
{ name, ... }: {
  container = {
    image = "lscr.io/linuxserver/sonarr";
    configVolume = "/config";
    volumes = [
      "/storage/scratch/torrent:/torrent"
      "/storage/scratch/usenet:/usenet"
      "/storage/media:/media"
    ];
    environment = {
      PUID = toString config.users.users.josh.uid;
      PGID = toString config.users.groups.media.gid;
      TZ = config.time.timeZone;
    };
    ports = [ "8989" ];
  };
}
```

#### Container Service with Dynamic Volumes

When you need to use the `storagePath` function to mount extra storage paths, use the function form:

```nix
{ config, ... }:
{
  requires = [ "storage-media.mount" ];
  container = {
    image = "ghcr.io/advplyr/audiobookshelf";
    environment = {
      TZ = config.time.timeZone;
    };
    ports = [ "80" ];
    configVolume = "/config";
    extraStorage = [ "audiobookshelf_metadata" ];  # Define extra storage
    volumes = storagePath: [
      "/storage/media:/media"
      "${storagePath "audiobookshelf_metadata"}:/metadata"  # Use storagePath for extra storage
    ];
  };
}
```

### Systemd Service Example

For native systemd services:

```nix
{ pkgs, ... }:
{
  systemd = {
    macvlan = true;
    tcpPorts = [ 7 ];
    udpPorts = [ 7 ];
    path = [ pkgs.socat ];
    script = { interface, ip, ip6, ... }: ''
      # Start TCP echo server on IPv4
      socat TCP4-LISTEN:7,bind=${ip},fork,reuseaddr EXEC:cat &

      # Start UDP echo server on IPv4
      socat UDP4-LISTEN:7,bind=${ip},fork,reuseaddr EXEC:cat &

      # Start TCP echo server on IPv6
      socat TCP6-LISTEN:7,bind=[${ip6}],fork,reuseaddr EXEC:cat &

      # Start UDP echo server on IPv6
      socat UDP6-LISTEN:7,bind=[${ip6}],fork,reuseaddr EXEC:cat &

      echo "Echo service started on ${interface} (${ip} / ${ip6})"
      wait
    '';
  };
}
```
