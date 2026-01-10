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
    ./opengear.nix
    ./services
  ];

  networking.hostName = "rt-ggz";
  boot = {
    kernelParams = [ "console=ttyS0,115200n8" ];
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;

      grub.extraConfig = "
       serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1
        terminal_input serial
        terminal_output serial
      ";
    };
  };

  system.stateVersion = "23.05";
  home-manager.users.${user0.name}.home.stateVersion = "24.11";
}
