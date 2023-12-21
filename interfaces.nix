{ ... }: {
  networking.interfaces.eno1.useDHCP = true;
  networking.interfaces.eno2.useDHCP = true;
  networking.interfaces.eno3.useDHCP = true;
  networking.interfaces.eno4.useDHCP = true;
  networking.interfaces.enp5s0f0.useDHCP = true;
  networking.interfaces.enp5s0f1.useDHCP = true;
}
