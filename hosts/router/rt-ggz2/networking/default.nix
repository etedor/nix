{ ... }:

{
  imports = [
    ./interfaces.nix
    ./routing
    ./tuning.nix
    ./vlans.nix
    ./wireguard.nix
  ];

  networking = {
    hostName = "rt-ggz2";
    useDHCP = false;
  };

  systemd.network.enable = true;
  systemd.network.wait-online.enable = false;
}
