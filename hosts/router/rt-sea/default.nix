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

  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
  };

  system.stateVersion = "23.05";
  home-manager.users.${user0.name}.home.stateVersion = "24.11";
}
