{
  lib,
  config,
  ...
}:

let
  mkInterfaces =
    cfg:
    let
      netdevs = builtins.attrValues cfg.systemd.network.netdevs;
      # filter for WireGuard netdevs and extract their names
      wireguardNetdevs = builtins.filter (netdev: netdev.netdevConfig.Kind or "" == "wireguard") netdevs;
    in
    builtins.map (netdev: netdev.netdevConfig.Name) wireguardNetdevs;

  mkPorts =
    cfg:
    let
      netdevs = builtins.attrValues cfg.systemd.network.netdevs;
      # filter for WireGuard netdevs
      wireguardNetdevs = builtins.filter (netdev: netdev.netdevConfig.Kind or "" == "wireguard") netdevs;
    in
    builtins.map (netdev: netdev.wireguardConfig.ListenPort) wireguardNetdevs;
in
{
  options.et42.router.wireguard = {
    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of WireGuard interfaces for the router";
      default = mkInterfaces config;
    };

    listenPorts = lib.mkOption {
      type = lib.types.listOf lib.types.int;
      description = "List of WireGuard listen ports for the router";
      default = mkPorts config;
    };

    publicKeys = lib.mkOption {
      type = lib.types.attrs;
      description = "WireGuard public keys for routers and clients";
      default = import ./keys.nix;
    };
  };
}
