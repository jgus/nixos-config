# Echo service - proof-of-concept for systemd services with macvlan networking
# Implements RFC 862 echo protocol on TCP and UDP port 7
{ lib, pkgs, ... }:
{
  homelab.services.echo = {
    configStorage = false;
    systemd = {
      path = [ pkgs.socat ];
      script =
        let
          ip = lib.homelab.nameToIp.echo;
          ip6 = lib.homelab.nameToIp6.echo;
        in
        ''
          # Start TCP echo server on IPv4
          socat TCP4-LISTEN:7,bind=${ip},fork,reuseaddr EXEC:cat &
      
          # Start UDP echo server on IPv4
          socat UDP4-LISTEN:7,bind=${ip},fork,reuseaddr EXEC:cat &
      
          # Start TCP echo server on IPv6
          socat TCP6-LISTEN:7,bind=[${ip6}],fork,reuseaddr EXEC:cat &
      
          # Start UDP echo server on IPv6
          socat UDP6-LISTEN:7,bind=[${ip6}],fork,reuseaddr EXEC:cat &
      
          echo "Echo service started on ${lib.homelab.macvlanInterfaceName "echo"} (${ip} / ${ip6})"
      
          # Wait forever (until service is stopped)
          wait
        '';
      macvlan = true;
      tcpPorts = [ 7 ];
      udpPorts = [ 7 ];
    };
  };
}
