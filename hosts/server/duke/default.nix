{
  globals,
  ...
}:

let
  user0 = globals.users 0;
  keys = globals.keys;
in
{
  imports = [
    ./hardware.nix
    ./networking
    ./services
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # nixremote: unprivileged user for distributed builds
  # no password = can't password login or su, only SSH key auth
  users.users.nixremote = {
    isNormalUser = true;
    home = "/var/empty";
    group = "nogroup";
    openssh.authorizedKeys.keys = builtins.attrValues keys.builders;
  };
  nix.settings.trusted-users = [ "nixremote" ];

  system.stateVersion = "23.05";
  home-manager.users.${user0.name}.home.stateVersion = "24.11";
}
