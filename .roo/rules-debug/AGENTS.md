# Project Debug Rules (Non-Obvious Only)

- Service network configurations are defined in `addresses.nix`
- Macvlan services use custom routing tables (1000+ range)
- Service storage paths are automatically created and backed up
- Docker services use macvlan networking with specific IP/MAC assignments
