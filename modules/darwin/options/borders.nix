{
  config,
  globals,
  lib,
  ...
}:

let
  user0 = globals.users 0;
  cfg = config.et42.device.borders;

  # allow vscode color previews
  stripHash = s: lib.removePrefix "#" s;
in
{
  options.et42.device.borders = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    activeColor = lib.mkOption {
      type = lib.types.str;
      default = "#00a5ff"; # macOS blue
    };
    activeAlpha = lib.mkOption {
      type = lib.types.str;
      default = "ff"; # fully opaque
    };
    inactiveColor = lib.mkOption {
      type = lib.types.str;
      default = "#48484c"; # macOS gray
    };
    inactiveAlpha = lib.mkOption {
      type = lib.types.str;
      default = "b3"; # 70% opacity
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${user0.name}.services.jankyborders = {
      enable = true;
      settings = {
        active_color = "0x${cfg.activeAlpha}${stripHash cfg.activeColor}";
        inactive_color = "0x${cfg.inactiveAlpha}${stripHash cfg.inactiveColor}";
        width = 4.0;
        style = "round";
        hidpi = true;
      };
    };
  };
}
