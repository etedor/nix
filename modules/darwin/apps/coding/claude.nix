{
  claude-code-pkg,
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
    claude-code-pkg
    # pkgs-unstable.mcp-nixos  # disabled: py-key-value-aio test failures
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

      home.activation.configureClaudeMcp =
        let
          mcpConfig = {
            mcpServers = {
              # nixos.command = "mcp-nixos";  # disabled
              time = {
                command = "uvx";
                args = [ "mcp-server-time" ];
              };
            };
          };
          desired = builtins.toJSON mcpConfig;
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

      home.activation.configureClaudeSettings =
        let
          settingsConfig = {
            env = {
              CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
            };
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
          desired = builtins.toJSON settingsConfig;
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
