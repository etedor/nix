{
  config,
  globals,
  lib,
  pkgs,
  ...
}:

let
  user0 = globals.users 0;
  cfg = config.et42.device.hammerspoon;

  spoonInstall = pkgs.fetchzip {
    url = "https://github.com/Hammerspoon/Spoons/raw/30b4f6013d48bd000a8ddecff23e5a8cce40c73c/Spoons/SpoonInstall.spoon.zip";
    sha256 = "sha256-VIlJT9IQ39cYcR3PaaMtkBIH6ndErPqhHGOKybOp9/s=";
    stripRoot = false;
  };

  # generate init.lua using SpoonInstall
  initLua = ''
    hs.loadSpoon("SpoonInstall")

    spoon.SpoonInstall.repos.windowmanager = {
      url = "https://github.com/etedor/hammerspoon",
      desc = "window management spoon",
      branch = "master"
    }

    spoon.SpoonInstall.use_syncinstall = true

    spoon.SpoonInstall:updateRepo("windowmanager")

    spoon.SpoonInstall:andUse("WindowManager", {
      repo = "windowmanager",
      start = true,
      config = {
        padding = ${toString cfg.padding},
        ultrawideThreshold = ${toString cfg.ultrawideThreshold},
        ultrawideLeftWidth = ${toString cfg.ultrawideLeftWidth},
        ultrawideCenterWidth = ${toString cfg.ultrawideCenterWidth},
        ultrawideRightWidth = ${toString cfg.ultrawideRightWidth},
        standardLeftWidth = ${toString cfg.standardLeftWidth},
        standardRightWidth = ${toString cfg.standardRightWidth},
        terminalApp = "${cfg.terminalApp}",
        enableInputToggle = ${if cfg.enableInputToggle then "true" else "false"},
      }
    })
  '';
in
{
  options.et42.device.hammerspoon = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    padding = lib.mkOption {
      type = lib.types.int;
      default = 0;
      description = "gap between tiles and screen edges (px)";
    };
    ultrawideThreshold = lib.mkOption {
      type = lib.types.float;
      default = 2.0;
      description = "aspect ratio threshold for ultrawide detection (21:9 ≈ 2.33, 16:9 ≈ 1.78)";
    };
    ultrawideLeftWidth = lib.mkOption {
      type = lib.types.float;
      default = 0.30;
      description = "ultrawide left column width (0.0-1.0)";
    };
    ultrawideCenterWidth = lib.mkOption {
      type = lib.types.float;
      default = 0.40;
      description = "ultrawide center column width (0.0-1.0)";
    };
    ultrawideRightWidth = lib.mkOption {
      type = lib.types.float;
      default = 0.30;
      description = "ultrawide right column width (0.0-1.0)";
    };
    standardLeftWidth = lib.mkOption {
      type = lib.types.float;
      default = 0.50;
      description = "standard left column width (0.0-1.0)";
    };
    standardRightWidth = lib.mkOption {
      type = lib.types.float;
      default = 0.50;
      description = "standard right column width (0.0-1.0)";
    };
    terminalApp = lib.mkOption {
      type = lib.types.str;
      default = "Ghostty";
      description = "terminal app for cmd+` toggle";
    };
    enableInputToggle = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "ctrl+alt+cmd+i toggle monitor input (requires m1ddc)";
    };
  };

  config = lib.mkIf cfg.enable {
    homebrew.casks = [ "hammerspoon" ];

    home-manager.users.${user0.name}.home.file = {
      ".hammerspoon/init.lua".text = initLua;
      ".hammerspoon/Spoons/SpoonInstall.spoon".source = "${spoonInstall}/SpoonInstall.spoon";
    };
  };
}
