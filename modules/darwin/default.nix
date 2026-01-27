# manual setup required:
# - 1password browser extension
# - mobileconfig profiles
# - apple watch unlock

{
  globals,
  pkgs-unstable,
  ...
}:

let
  user0 = globals.users 0;
in
{
  imports = [
    ./apps
    ./fonts.nix
    ./mounts.nix
    ./options/autofs.nix
    ./options/wallpaper.nix
  ];

  # shared workflow configuration
  et42.workflow = {
    user = user0.name;

    system = {
      dock.enable = true;
      input.enable = true;
      spaces.enable = true;
    };

    apps = {
      borders.enable = true;
      hammerspoon.enable = true;
      ice.enable = true;
      shortcat.enable = true;
      vscode = {
        enable = true;
        package = pkgs-unstable.vscode;
        extensionPkgs = pkgs-unstable;
        fontFamily = "'Font Awesome', 'FiraCode Nerd Font', 'monospace'";
      };
    };
  };
}
