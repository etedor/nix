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
    ./fonts.nix
    ./input.nix
    ./mounts.nix
    ./options
    ./options/wallpaper.nix
    ./spaces.nix
  ];
}
