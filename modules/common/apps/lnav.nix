{
  globals,
  mkModule,
  pkgs,
  ...
}:

let
  user0 = globals.users 0;
in
mkModule {
  shared = {
    home-manager.users.${user0.name} = {
      home.packages = [ pkgs.lnav ];

      xdg.configFile."lnav/configs/installed/default-config.json".text = builtins.toJSON {
        "$schema" = "https://lnav.org/schemas/config-v1.schema.json";
        ui = {
          theme = "eldar";
        };
      };
    };
  };
}
