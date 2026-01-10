{
  globals,
  pkgs,
  ...
}:

let
  user1 = globals.users 1;
in
{
  homebrew.casks = [
    "bambu-studio"
  ];

  users.users.${user1.name}.packages = with pkgs; [
    google-chrome
  ];
}
