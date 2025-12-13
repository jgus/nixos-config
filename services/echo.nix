# Echo service - proof-of-concept for systemd services with macvlan networking
# Implements RFC 862 echo protocol on TCP and UDP port 7
{ pkgs, ... }:
{
  configStorage = false;
  systemd = {
    macvlan = true;
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
      
      # Wait forever (until service is stopped)
      wait
    '';
  };
}
