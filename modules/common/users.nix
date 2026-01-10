{
  globals,
  mkModule,
  ...
}:

let
  user0 = globals.users 0;
in
mkModule {
  shared = {
    users.users.${user0.name} = {
      description = user0.fullName;
    };
  };

  linux = {
    users.groups.${user0.name} = { };
    users.users.${user0.name} = {
      isNormalUser = true;
      group = user0.name;
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
    };
  };

  darwin = {
    users.knownUsers = [
      user0.name
    ];

    users.users.${user0.name} = {
      name = user0.name;
      description = user0.fullName;
      home = "/Users/${user0.name}";
      uid = 501;
    };
  };
}
