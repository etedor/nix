{ ... }:
{
  imports = [
    ./blocky
    ./cake.nix
    ./frr.nix
    ./kea.nix
    ./miniupnpd.nix
    ./nftables.nix
    ./nsd.nix
    ./router.nix
    ./unbound.nix
    ./wireguard
  ];
}
