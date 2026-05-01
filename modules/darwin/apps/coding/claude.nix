{
  claude-code-pkg,
  globals,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}:

let
  user0 = globals.users 0;

  # hosts with claude user = NixOS hosts (routers + servers)
  claudeHosts = builtins.attrNames globals.routers
    ++ builtins.filter (n: !builtins.hasAttr n globals.routers) (
      builtins.filter (n: n != "brother" && n != "home-assistant" && n != "ntp" && n != "machina")
        (builtins.attrNames globals.hosts)
    );

  # switches from SSH config
  sshHosts = import ../../../common/services/ssh/hosts.nix { inherit globals; } user0.name;
  switchHosts = builtins.filter (n: lib.hasPrefix "sw-" n) (builtins.attrNames sshHosts);

  pythonEnv = pkgs.python3.withPackages (ps: with ps; [ netmiko ]);
  switch-cli = pkgs.writeScriptBin "switch-cli" ''
    #!${pythonEnv}/bin/python3
    ${builtins.readFile ./bin/switch-cli.py}
  '';
  claude-run = pkgs.writeShellScriptBin "claude-run" ''
    CLAUDE_HOSTS="${lib.concatStringsSep " " (lib.naturalSort claudeHosts)}"
    CLAUDE_SWITCHES="${lib.concatStringsSep " " (lib.naturalSort switchHosts)}"
    ${builtins.readFile ./bin/claude-run.sh}
  '';
  cols-hook = pkgs.writeShellApplication {
    name = "claude-cols-hook";
    runtimeInputs = [ pkgs.jq ];
    text = builtins.readFile ./bin/claude-cols-hook.sh;
  };
in
{
  users.users.${user0.name}.packages = [
    claude-code-pkg
    claude-run
    switch-cli
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

      home.file.".claude/plugins/go-lsp/.claude-plugin/plugin.json".text = builtins.toJSON {
        name = "go-lsp-direnv";
        description = "gopls via direnv for nix flake dev shells";
        version = "1.0.0";
      };

      home.file.".claude/plugins/go-lsp/.lsp.json".text = builtins.toJSON {
        go = {
          command = "direnv";
          args = [ "exec" "." "gopls" "serve" ];
          extensionToLanguage = {
            ".go" = "go";
          };
        };
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

          # remove switch MCP server (replaced by claude-run CLI)
          if [ -f "$CONFIG" ]; then
            ${pkgs.jq}/bin/jq 'del(.mcpServers.switch)' "$CONFIG" > "$CONFIG.tmp" \
              && mv "$CONFIG.tmp" "$CONFIG"
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
              SessionStart = [
                {
                  hooks = [
                    {
                      type = "command";
                      command = "${cols-hook}/bin/claude-cols-hook SessionStart";
                    }
                  ];
                }
              ];
              UserPromptSubmit = [
                {
                  hooks = [
                    {
                      type = "command";
                      command = "${cols-hook}/bin/claude-cols-hook UserPromptSubmit";
                    }
                  ];
                }
              ];
              PostCompact = [
                {
                  hooks = [
                    {
                      type = "command";
                      command = "${cols-hook}/bin/claude-cols-hook PostCompact";
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
