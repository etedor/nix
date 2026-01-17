{
  config,
  globals,
  lib,
  ...
}:

let
  user0 = globals.users 0;
in
{
  homebrew.casks = [ "mouseless@preview" ];

  home-manager.users.${user0.name} = { config, ... }: {
    # source of truth in version control
    home.file.".config/mouseless/config.yaml".source = ./config.yaml;

    # copy to container on activation
    home.activation.mouselessConfig = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      CONTAINER_PATH="$HOME/Library/Containers/net.sonuscape.mouseless/Data/.mouseless/configs"
      if [ -d "$CONTAINER_PATH" ]; then
        $DRY_RUN_CMD mkdir -p "$CONTAINER_PATH"
        $DRY_RUN_CMD cp -f "$HOME/.config/mouseless/config.yaml" "$CONTAINER_PATH/config.yaml"
        echo "Copied mouseless config to container"
      else
        echo "Mouseless container not found - config will be copied on next activation after app first run"
      fi
    '';
  };
}
