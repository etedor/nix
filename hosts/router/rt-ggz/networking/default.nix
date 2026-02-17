{
  globals,
  ...
}:

{
  imports = [
    ./interfaces.nix
    ./multicast.nix
    ./qos
    ./routing
    ./tuning.nix
    ./vlans.nix
    ./wan-failover
    ./wireguard.nix
  ];

  networking = {
    hostName = "rt-ggz";
    domain = globals.zones.home;
    useDHCP = false;
  };

  systemd.network.enable = true;
  systemd.network.wait-online.enable = false;
}
