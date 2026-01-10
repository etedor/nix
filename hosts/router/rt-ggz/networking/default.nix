{
  globals,
  ...
}:

{
  imports = [
    ./interfaces.nix
    ./multicast.nix
    ./qos
    ./routing.nix
    ./tuning.nix
    ./vlans.nix
    ./wan-failover
    ./wireguard.nix
  ];

  networking = {
    hostName = "rt-ggz";
    domain = globals.zone;
    useDHCP = false;
  };

  systemd.network.enable = true;
  systemd.network.wait-online.enable = false;
}
