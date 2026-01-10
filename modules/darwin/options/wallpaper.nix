{
  config,
  globals,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.et42.device.wallpaper;
  user0 = globals.users 0;
in
{
  options.et42.device.wallpaper = {
    enable = lib.mkEnableOption "desktop wallpaper management";

    image = lib.mkOption {
      type = lib.types.path;
      description = "Path to wallpaper image file.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.desktoppr ];

    home-manager.users.${user0.name} = {
      launchd.agents.set-wallpaper = {
        enable = true;
        config = {
          ProgramArguments = [
            "${pkgs.desktoppr}/bin/desktoppr"
            "${cfg.image}"
          ];
          RunAtLoad = true;
        };
      };
    };
  };
}
