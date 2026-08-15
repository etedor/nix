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

  # ASD-STE100 simplified technical english skill plugin
  simple-english-src = pkgs.fetchFromGitHub {
    owner = "AminBlg";
    repo = "SimpleEnglish";
    rev = "59bf6702197a5aadc96d197ea17f290d8d50dcd3";
    sha256 = "sha256-QmlV9OZ4CNxI+pV7jDcn4n3Zet1+9W7h5oTNCUQ/vrY=";
  };

  # ASD-STE100 linter (unofficial, MIT/OpenSTE wordset) — provides `vale mcp`
  vale-ste = pkgs.buildGoModule {
    pname = "vale-ste";
    version = "0-unstable-2026-08-15";
    src = pkgs.fetchFromGitHub {
      owner = "stuffbucket";
      repo = "vale";
      rev = "d96df3eb63f174b6933e29f3d97d4f17e74ab7c3";
      sha256 = "sha256-OQJMFhflZkzdWoFAI9z/JIPbNR5Cgutu89CEzjYVUq4=";
    };
    vendorHash = "sha256-l3YB3z+9IiuG0B6KERpmnZ3GgT/zNVQ4XtffG4zS1Jg=";
    subPackages = [ "cmd/vale" ];
    meta.description = "ASD-STE100 simplified technical english linter";
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
          # ASD-STE100 deterministic linter (OpenSTE wordset)
          ste-vale = {
            command = "${vale-ste}/bin/vale";
            args = [ "mcp" ];
          };
          # ASD-STE100 issue 9 vocabulary/rules lookup (read-only, AGPL, run not vendored)
          ste-vocab = {
            command = "uvx";
            args = [ "--from" "biz-dfch-asdste100mcp" "asdste100-mcp" ];
          };
        };

        plugins = [
          go-lsp-plugin
          superpowers-src
          ponytail-src
          simple-english-src
        ];

        settings = {
          env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
          tui = "fullscreen";
          outputStyle = "Terse";
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

      home.file.".claude/output-styles/terse.md".source = ./output-styles/terse.md;

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
