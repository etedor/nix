# M4 MacBook Air 13"

{ ... }:

{
  imports = [
    ./desktop
    ./wireguard.nix
  ];

  networking.computerName = "Carbon";
  networking.hostName = "carbon";
}
