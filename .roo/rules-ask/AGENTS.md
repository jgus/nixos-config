# Project Documentation Rules (Non-Obvious Only)

- Services are defined in `addresses.nix` with host assignments
- Service configuration files in `services/` directory determine service behavior
- Container services use macvlan networking with unique MAC addresses
- Systemd services can also use macvlan networking for isolated network access
- The `storagePath` function provides paths to automatically created storage
- Service dependencies must be declared via the `requires` attribute
