# Project Coding Rules (Non-Obvious Only)

- Always declare service dependencies via the `requires` attribute in service definitions
- Services MUST require mount points that they depend on (e.g., "storage-media.mount")
- Use `storagePath` function for volume mounts in Container services, to get the path to automatically created storage
- Service hosts in `addresses.nix` determine which machine hosts the service
- MACHINE_ID environment variable is required when building configurations for remote machines
- Services are EITHER container-based OR systemd-based - never both in the same service
- Extra storage paths declared via `extraStorage` attribute are automatically backed up
- Systemd services with `macvlan = true` receive network interface details in the script context
