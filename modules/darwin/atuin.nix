{ config, globals, specialArgs, ... }:

let
  user0 = globals.users 0;
in
{
  age.secrets.atuin = {
    file = "${specialArgs.secretsRole}/atuin.age";
    owner = user0.name;
    group = "staff";
    mode = "0400";
  };

  home-manager.users.${user0.name}.programs.atuin.settings = {
    sync_address = "https://atuin.${globals.zone}";
    key_path = config.age.secrets.atuin.path;
  };
}
