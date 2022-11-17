{ ... }: {
  networking.interfaces.enp2s0f0.useDHCP = true;
  networking.interfaces.enp2s0f1.useDHCP = true;
  networking.interfaces.enp2s0f2.useDHCP = true;
  networking.interfaces.enp2s0f3.useDHCP = true;
  networking.interfaces.enp10s0f0.useDHCP = true;
  networking.interfaces.enp10s0f1 = {
    useDHCP = false;
    ipv4.addresses = [
      {
        address = "172.22.1.9";
        prefixLength = 15;
      }
    ];
  };
}
