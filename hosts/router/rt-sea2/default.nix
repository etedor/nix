{
  globals,
  inputs,
  ...
}:

let
  user0 = globals.users 0;
in
{
  imports = [
    inputs.disko.nixosModules.disko
    ./disko.nix
    ./hardware.nix
    ./networking
    ./services
  ];

  # grub boot device (/dev/vda) is registered by ./disko.nix via the bios_grub partition
  boot.loader.grub.enable = true;

  system.stateVersion = "25.05";
  home-manager.users.${user0.name}.home.stateVersion = "25.05";
}
