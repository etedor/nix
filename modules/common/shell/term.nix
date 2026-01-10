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
    home-manager.users.${user0.name} = {
      programs.ghostty = {
        enableFishIntegration = true;
        settings = {
          font-family = "FiraCode Nerd Font";
          font-size = 10;
          theme = "Monokai Pro Machine";
          window-padding-x = 16;
          window-padding-y = 16;
          keybind = "shift+enter=text:\\n";
        };
      };
    };
  };

  linux = {
    home-manager.users.${user0.name} = {
      programs.ghostty = {
        enable = true;
      };
    };
  };

  darwin = {
    homebrew.casks = [
      "ghostty"
    ];

    system.activationScripts.extraActivation = {
      enable = true;
      text = ''
        if [ -d "/Applications/Ghostty.app/Contents/Resources/terminfo" ]; then
          if ! infocmp ghostty &>/dev/null; then
            TERMINFO="/Applications/Ghostty.app/Contents/Resources/terminfo" \
              infocmp -x ghostty | tic -x -
          fi
          if ! infocmp xterm-ghostty &>/dev/null; then
            TERMINFO="/Applications/Ghostty.app/Contents/Resources/terminfo" \
              infocmp -x xterm-ghostty | tic -x -
          fi
        fi
      '';
    };
  };
}
