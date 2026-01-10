{
  globals,
  pkgs,
  pkgs-unstable,
  ...
}:

let
  user0 = globals.users 0;
in
{
  environment.systemPackages = with pkgs; [
    nil
  ];
  programs.direnv.enable = true;

  home-manager.users.${user0.name} = {
    programs.vscode = {
      enable = true;
      package = pkgs-unstable.vscode;

      profiles.default = {
        extensions = import ./extensions.nix { pkgs-unstable = pkgs-unstable; };
        userSettings = {
          "[nix]".editor.defaultFormatter = "jnoortheen.nix-ide";
          "[json]".editor.defaultFormatter = "esbenp.prettier-vscode";
          "[yaml]".editor.defaultFormatter = "esbenp.prettier-vscode";
          "[markdown]".editor.defaultFormatter = "esbenp.prettier-vscode";
          "[python]".editor.defaultFormatter = "ms-python.black-formatter";
          "[shellscript]".editor.defaultFormatter = "foxundermoon.shell-format";
          nix = {
            enableLanguageServer = true;
            serverPath = "nil";
            serverSettings.nil.nix.flake.autoArchive = true;
          };

          editor = {
            fontFamily = "'Font Awesome', 'FiraCode Nerd Font', 'monospace'";
            fontSize = 15;
            fontLigatures = true;

            formatOnSave = true;
            trimAutoWhitespace = true;

            stickyScroll.enabled = true;
          };

          window.zoomLevel = 0;
          explorer.decorations.colors = true;

          workbench = {
            colorTheme = "Monokai Pro";
            iconTheme = "Monokai Pro Icons";

            editor.labelFormat = "short";

            tree.indent = 12;
            tree.renderIndentGuides = "always";
          };

          "chat.disableAIFeatures" = true;
        };

        keybindings = [
          {
            key = "ctrl+tab";
            command = "workbench.action.nextEditorInGroup";
          }
          {
            key = "ctrl+shift+tab";
            command = "workbench.action.previousEditorInGroup";
          }
        ];
      };
    };
  };
}
