{ config, pkgs, ... }:

{
  environment.etc = {
    ".secrets/wireguard-private-key".source = ./.secrets/wireguard-private-key;
  };

  networking = {
    nat = {
      enable = true;
      externalInterface = "enp5s0f1";
      internalInterfaces = [ "wg0" ];
    };
    firewall.allowedUDPPorts = [ 51820 ];

    wireguard.interfaces = {
      # "wg0" is the network interface name. You can name the interface arbitrarily.
      wg0 = {
        # Determines the IP address and subnet of the server's end of the tunnel interface.
        ips = [ "172.23.0.1/24" ];

        # The port that WireGuard listens to. Must be accessible by the client.
        listenPort = 51820;

        # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
        # For this to work you have to set the dnsserver IP of your router (or dnsserver of choice) in your clients
        postSetup = ''
          ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 172.23.0.0/24 -o enp5s0f1 -j MASQUERADE
        '';

        # This undoes the above command
        postShutdown = ''
          ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 172.23.0.0/24 -o enp5s0f1 -j MASQUERADE
        '';

        # Path to the private key file.
        #
        # Note: The private key can also be included inline via the privateKey option,
        # but this makes the private key world-readable; thus, using privateKeyFile is
        # recommended.
        privateKeyFile = "/etc/.secrets/wireguard-private-key";

        peers = [
          # List of allowed peers.
          { # Josh-X1
            publicKey = "MhTvktvI9KXTHqdB6J4Z/KEgfS/R5hiX8oIAJyzZfDo=";
            allowedIPs = [ "172.23.0.2/32" ];
          }
        ];
      };
    };
  };
}
