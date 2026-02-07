{
  globals,
  ...
}:

let
  user0 = globals.users 0;
in
{
  imports = [
    ./hardware.nix
    ./networking
    ./services
  ];

  networking.hostName = "rt-ggz2";

  system.stateVersion = "24.11";
  home-manager.users.${user0.name}.home.stateVersion = "24.11";
}
