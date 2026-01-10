{
  globals,
  ...
}:

let
  user0 = globals.users 0;
in
{
  home-manager.users.${user0.name}.programs.discord = {
    enable = true;
    settings.SKIP_HOST_UPDATE = true;
  };
}
