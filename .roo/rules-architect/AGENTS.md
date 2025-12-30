# Project Architecture Rules (Non-Obvious Only)

- Service-to-host mapping is defined in `addresses.nix`, not in service files
- MAC addresses are auto-generated from group/ID for services without explicit MACs
- IPv6 addresses use EUI-64 format derived from MAC addresses
- Custom routing tables (1000+) are used for macvlan services to prevent route conflicts
- Service storage is automatically created as ZFS datasets when ZFS is available
- All service storage is backed up hourly via rsync to backup paths
- Container and systemd services cannot be mixed in the same service definition
