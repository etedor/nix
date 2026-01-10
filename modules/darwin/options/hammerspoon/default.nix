{
  config,
  globals,
  lib,
  ...
}:

let
  user0 = globals.users 0;
  cfg = config.et42.device.hammerspoon;

  # generate init.lua content based on enabled modules
  initLua = ''
    --[[
      macos system hotkeys:
        ctrl+←/→         adjacent workspace
        ctrl+↑           mission control
        ctrl+↓           app exposé

      hotkey logic:
        ctrl+alt         window tiling
        cmd              window focus
        ctrl+cmd         cluster cycling
        ctrl+alt+cmd     hammerspoon meta

      custom bindings:
        ctrl+alt+1-9          switch to workspace N

        ctrl+alt+arrow        tile (adapts to screen aspect ratio)
        ctrl+alt+arrow+arrow  tile quarter/sixth (perpendicular)
        ctrl+alt+f            fill
        ctrl+alt+c            center
        ctrl+alt+t            float on top

        cmd+←/→/↑/↓           focus window (spatial)
        ctrl+cmd+↑/↓          cycle overlapping cluster

        cmd+tab               toggle last two windows
        cmd+`                 focus ghostty

        ctrl+alt+cmd+r        reload config
        ctrl+alt+cmd+i        toggle monitor input
    ]]

    hs.alert.show("Hammerspoon loaded")
    ${lib.optionalString cfg.modules.reload ''require("reload")''}
    ${lib.optionalString cfg.modules.workspaces ''require("workspaces")''}
    ${lib.optionalString cfg.modules.tiling ''require("tiling")''}
    ${lib.optionalString cfg.modules.focusSpatial ''require("focus-spatial")''}
    ${lib.optionalString cfg.modules.focusCluster ''require("focus-cluster")''}
    ${lib.optionalString cfg.modules.switcher ''require("switcher")''}
    ${lib.optionalString cfg.modules.displayToggle ''require("display-toggle")''}
  '';

  luaFiles = lib.flatten [
    (lib.optional cfg.modules.reload "reload.lua")
    (lib.optional cfg.modules.workspaces "workspaces.lua")
    (lib.optional cfg.modules.tiling "tiling.lua")
    (lib.optional cfg.modules.focusSpatial "focus-spatial.lua")
    (lib.optional cfg.modules.focusCluster "focus-cluster.lua")
    (lib.optional cfg.modules.switcher "switcher.lua")
    (lib.optional cfg.modules.displayToggle "display-toggle.lua")
  ];
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
    modules = {
      reload = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "ctrl+alt+cmd+R to reload config";
      };
      workspaces = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "ctrl+alt+1-9 workspace switching";
      };
      tiling = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "ctrl+alt+arrows adaptive tiling (auto-detects ultrawide)";
      };
      focusSpatial = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "cmd+arrows spatial focus";
      };
      focusCluster = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "ctrl+cmd+up/down cluster cycling";
      };
      switcher = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "cmd+tab toggle, cmd+` ghostty";
      };
      displayToggle = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "ctrl+alt+cmd+i toggle monitor input";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    homebrew.casks = [ "hammerspoon" ];

    home-manager.users.${user0.name}.home.file = {
      ".hammerspoon/init.lua".text = initLua;
      ".hammerspoon/settings.lua".text = ''
        return {
          padding = ${toString cfg.padding},
          ultrawideThreshold = ${toString cfg.ultrawideThreshold},
        }
      '';
    }
    // lib.listToAttrs (
      map (f: {
        name = ".hammerspoon/${f}";
        value = {
          source = ./${f};
        };
      }) luaFiles
    )
    // lib.optionalAttrs cfg.modules.displayToggle {
      ".hammerspoon/toggle-input.sh" = {
        source = ./toggle-input.sh;
        executable = true;
      };
    };
  };
}
