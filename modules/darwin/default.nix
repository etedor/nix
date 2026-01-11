# manual setup required:
# - 1password browser extension
# - mobileconfig profiles
# - apple watch unlock

{
  ...
}:

{
  imports = [
    ./apps
    ./atuin.nix
    ./fonts.nix
    ./input.nix
    ./mounts.nix
    ./options
    ./options/wallpaper.nix
  ];
}
