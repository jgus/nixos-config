{ ... }:

{
  time.timeZone = "America/Denver";

  environment.etc = {
    "ssh/ssh_host_ed25519_key" = {
      source = ./.secrets/ssh/ssh_host_ed25519_key;
      mode = "0600";
    };
    "ssh/ssh_host_ed25519_key.pub" = {
      source = ./.secrets/ssh/ssh_host_ed25519_key.pub;
      mode = "0644";
    };
    "ssh/ssh_host_rsa_key" = {
      source = ./.secrets/ssh/ssh_host_rsa_key;
      mode = "0600";
    };
    "ssh/ssh_host_rsa_key.pub" = {
      source = ./.secrets/ssh/ssh_host_rsa_key.pub;
      mode = "0644";
    };
  };

  networking = {
    hostName = "c240m3";
    hostId = "04b22318"; # head -c4 /dev/urandom | od -A none -t x4
    defaultGateway = {
      address = "172.22.0.1";
      interface = "enp10s0f1";
    };
    nameservers = [
      "192.168.22.2"
      "1.1.1.1"
      "1.0.0.1"
    ];
    hosts = {
      "172.22.0.1" = [ "gateway.gustafson.me" "gateway" "router.gustafson.me" "router" ];
      "192.168.22.2" = [ "pi.hole" "dhcp" "dhcp.gustafson.me" "dns" "dns.gustafson.me" ];
      "172.22.1.3" = [ "sm1.gustafson.me" "sm1" "nas.gustafson.me" "syncthing" "syncthing.gustafson.me" "nas" ];
    };
  };
}
