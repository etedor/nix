{ ... }:

{
  imports = [
    ./dns-register.nix
    ./navidrome.nix
    ./nginx.nix
    ./radio.nix
  ];
}
