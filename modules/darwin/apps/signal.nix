{
  globals,
  pkgs,
  ...
}:

let
  user0 = globals.users 0;
in
{
  home-manager.users.${user0.name}.home.packages = [
    pkgs.signal-desktop-bin
  ];
}
