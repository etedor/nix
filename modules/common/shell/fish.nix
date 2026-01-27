{
  globals,
  lib,
  pkgs,
  mkModule,
  ...
}:

let
  user0 = globals.users 0;
in
mkModule {
  shared = {
    environment = {
      systemPackages = [ pkgs.fish ];
      variables.SHELL = "${pkgs.fish}/bin/fish";
    };

    users.users.${user0.name} = {
      shell = pkgs.fish;
      ignoreShellProgramCheck = true;
    };

    home-manager.users.${user0.name} = {
      programs.fish = {
        enable = true;
        interactiveShellInit = ''
          set fish_greeting
          starship init fish | source
        '';
      };

      programs.starship = {
        enable = true;
        settings = {
          hostname = {
            ssh_symbol = "📡 ";
            style = "bold green";
          };
          time = {
            disabled = false;
          };
        };
      };
    };
  };

  linux = { };

  darwin = {
    environment.shells = [ pkgs.fish ];
    home-manager.users.${user0.name}.programs.fish = {
      # nix path in shellInit so non-interactive SSH commands work (deploy-rs)
      shellInit =
        let
          # https://github.com/LnL7/nix-darwin/issues/122#issuecomment-1659465635
          # https://github.com/LnL7/nix-darwin/issues/947
          profiles = [
            "/etc/profiles/per-user/$USER"
            "$HOME/.nix-profile"
            "(set -q XDG_STATE_HOME; and echo $XDG_STATE_HOME; or echo $HOME/.local/state)/nix/profile"
            "/run/current-system/sw"
            "/nix/var/nix/profiles/default"
          ];
          makeBinSearchPath = lib.concatMapStringsSep " " (path: "${path}/bin");
        in
        ''
          set -gx NIX_PATH nixpkgs=flake:nixpkgs:/nix/var/nix/profiles/per-user/root/channels
          fish_add_path --move --prepend --path ${makeBinSearchPath profiles}
        '';
    };
  };
}
