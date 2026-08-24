{ ... }:
{
  imports = [
    ./anycast-health.nix
    ./blocky
    ./cake.nix
    ./frr.nix
    ./kea.nix
    ./miniupnpd.nix
    ./nftables.nix
    ./knot
    ./unbound.nix
    ./wireguard
  ];
}
