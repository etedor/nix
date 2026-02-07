{
  globals,
  ...
}:

let
  user0 = globals.users 0;
in
{
  home-manager.users.${user0.name}.programs.git = {
    enable = true;
    ignores = [ ".worktrees" ];
    settings.user = {
      name = user0.fullName;
      email = user0.email;
    };
  };
}
