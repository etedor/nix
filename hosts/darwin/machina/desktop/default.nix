{ globals, ... }:

let
  user0 = globals.users 0;
in
{
  et42.workflow.apps.borders.activeColor = "#01ff90";

  et42.device.wallpaper = {
    enable = true;
    image = ./wallhaven-kxrjjm.jpg;
  };

  home-manager.users.${user0.name}.home.file.".hammerspoon/local.lua".source = ./local.lua;
}
