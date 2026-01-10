{
  config,
  lib,
  ...
}:

let
  cfg = config.et42.device.dock;
in
{
  options.et42.device.dock = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    orientation = lib.mkOption {
      type = lib.types.enum [
        "bottom"
        "left"
        "right"
      ];
      default = "right";
    };
    autohide = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    persistentApps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    system.defaults.dock = {
      inherit (cfg) orientation autohide;

      persistent-apps = lib.mkIf (cfg.persistentApps != [ ]) cfg.persistentApps;

      tilesize = 48;
      magnification = false;
      launchanim = false;
      show-recents = false;
      mru-spaces = false;
      mineffect = "scale";
      minimize-to-application = true;
      wvous-br-corner = 1; # disable quick note
    };
  };
}
