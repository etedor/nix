{ ... }:
{
  imports = [
    ./blocky
    ./cake.nix
    ./frr.nix
    ./kea.nix
    ./miniupnpd.nix
    ./nftables.nix
    ./knot.nix
    ./unbound.nix
    ./wireguard
  ];
}
