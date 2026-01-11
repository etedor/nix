{ config, globals, specialArgs, ... }:

let
  user0 = globals.users 0;
in
{
  age.secrets.atuin-key = {
    file = "${specialArgs.secretsRole}/atuin-key.age";
    owner = user0.name;
    group = "staff";
    mode = "0400";
  };

  age.secrets.atuin-session = {
    file = "${specialArgs.secretsRole}/atuin-session.age";
    owner = user0.name;
    group = "staff";
    mode = "0400";
  };

  home-manager.users.${user0.name}.programs.atuin.settings = {
    sync_address = "https://atuin.${globals.zone}";
    key_path = config.age.secrets.atuin-key.path;
    session_path = config.age.secrets.atuin-session.path;
  };
}
