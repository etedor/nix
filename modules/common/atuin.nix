{
  config,
  globals,
  mkModule,
  specialArgs,
  ...
}:

let
  user0 = globals.users 0;
in
mkModule {
  shared = {
    age.secrets.atuin-key = {
      file = "${specialArgs.secretsRole}/atuin-key.age";
      owner = user0.name;
      mode = "0400";
    };

    age.secrets.atuin-session = {
      file = "${specialArgs.secretsRole}/atuin-session.age";
      owner = user0.name;
      mode = "0400";
    };

    home-manager.users.${user0.name}.programs.atuin = {
      forceOverwriteSettings = true;
      settings = {
        sync_address = "https://atuin.${globals.zone}";
        key_path = config.age.secrets.atuin-key.path;
        session_path = config.age.secrets.atuin-session.path;
        filter_mode = "global";
      };
    };
  };

  linux = {
    age.secrets.atuin-key.group = "users";
    age.secrets.atuin-session.group = "users";
  };

  darwin = {
    age.secrets.atuin-key.group = "staff";
    age.secrets.atuin-session.group = "staff";
  };
}
