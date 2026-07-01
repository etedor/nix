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

  # plugin sources — pinned by commit SHA
  superpowers-src = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "f268f7c953744036f0fa7e9d4b73535c04e57cb8"; # v6.1.0
    sha256 = "0gksqggagakdpvzx41d6lsrp3mkmlbrkwpanljpz8k5f7rnmpwc2";
  };
  ponytail-src = pkgs.fetchFromGitHub {
    owner = "DietrichGebert";
    repo = "ponytail";
    rev = "16f6cbf4b87792938e47b0f8c650b6d80fcbc98c";
    sha256 = "0slyas4xzy5p89vmdskj33fqcjxk5f0isxjk655kqglwl4l5sv6m";
  };

  # local go-lsp plugin (was inline home.file JSON)
  go-lsp-plugin = pkgs.runCommand "go-lsp-plugin" { } ''
    mkdir -p $out/.claude-plugin
    cat > $out/.claude-plugin/plugin.json <<'EOF'
    ${builtins.toJSON {
      name = "go-lsp-direnv";
      description = "gopls via direnv for nix flake dev shells";
      version = "1.0.0";
    }}
    EOF
    cat > $out/.lsp.json <<'EOF'
    ${builtins.toJSON {
      go = {
        command = "direnv";
        args = [ "exec" "." "gopls" "serve" ];
        extensionToLanguage = {
          ".go" = "go";
        };
      };
    }}
    EOF
  '';
in
{
  users.users.${user0.name}.packages = [
    claude-run
    switch-cli
    pkgs-unstable.uv
  ];

  home-manager.users.${user0.name} =
    { lib, ... }:
    {
      programs.claude-code = {
        enable = true;
        package = claude-code-pkg;

        mcpServers = {
          nixos = {
            command = "uvx";
            args = [ "mcp-nixos" ];
          };
          time = {
            command = "uvx";
            args = [ "mcp-server-time" ];
          };
        };

        plugins = [
          go-lsp-plugin
          superpowers-src
          ponytail-src
        ];

        settings = {
          env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
          tui = "fullscreen";
          statusLine = {
            type = "command";
            command = "$HOME/.claude/statusline.sh";
            padding = 0;
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
        };
      };

      home.file.".claude/hooks/format-file.sh" = {
        executable = true;
        source = ./format-file.sh;
      };

      home.file.".claude/statusline.sh" = {
        executable = true;
        source = ./statusline.sh;
      };

      # one-time cleanup: strip legacy mcpServers from ~/.claude.json
      # (MCP servers now live in ~/.mcp.json via programs.claude-code)
      home.activation.cleanupLegacyClaudeMcp =
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          CONFIG="$HOME/.claude.json"
          if [ -f "$CONFIG" ] && ${pkgs.jq}/bin/jq -e '.mcpServers' "$CONFIG" > /dev/null; then
            ${pkgs.jq}/bin/jq 'del(.mcpServers)' "$CONFIG" > "$CONFIG.tmp" \
              && mv "$CONFIG.tmp" "$CONFIG"
          fi
        '';
    };
}
