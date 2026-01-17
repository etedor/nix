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
  users.users.${user0.name}.packages = [
    pkgs-unstable.claude-code
    pkgs-unstable.mcp-nixos
    pkgs-unstable.uv
  ];

  home-manager.users.${user0.name} =
    { lib, ... }:
    {
      home.file.".claude/hooks/format-file.sh" = {
        executable = true;
        source = ./format-file.sh;
      };

      home.file.".claude/statusline.sh" = {
        executable = true;
        source = ./statusline.sh;
      };

      home.activation.configureClaude =
        let
          claudeConfig = {
            mcpServers = {
              nixos.command = "mcp-nixos";
              time = {
                command = "uvx";
                args = [ "mcp-server-time" ];
              };
            };
          };
          desired = builtins.toJSON claudeConfig;
        in
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          CONFIG="$HOME/.claude.json"
          if [ -f "$CONFIG" ]; then
            ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$CONFIG" - <<< '${desired}' > "$CONFIG.tmp" \
              && mv "$CONFIG.tmp" "$CONFIG"
          else
            echo '${desired}' > "$CONFIG"
          fi
        '';

      home.activation.configureClaudeHooks =
        let
          hooksConfig = {
            hooks = {
              PostToolUse = [
                {
                  matcher = "Edit|Write";
                  hooks = [
                    {
                      type = "command";
                      command = "$HOME/.claude/hooks/format-file.sh";
                      timeout = 30;
                    }
                  ];
                }
              ];
            };
            statusLine = {
              type = "command";
              command = "$HOME/.claude/statusline.sh";
              padding = 0;
            };
          };
          desired = builtins.toJSON hooksConfig;
        in
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          CONFIG="$HOME/.claude/settings.json"
          mkdir -p "$HOME/.claude"
          if [ -f "$CONFIG" ]; then
            ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$CONFIG" - <<< '${desired}' > "$CONFIG.tmp" \
              && mv "$CONFIG.tmp" "$CONFIG"
          else
            echo '${desired}' > "$CONFIG"
          fi
        '';
    };
}
