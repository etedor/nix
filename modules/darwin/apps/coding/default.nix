{
  globals,
  pkgs,
  ...
}:

let
  user0 = globals.users 0;
in
{
  imports = [
    ./claude.nix
    ./vscode
  ];

  environment.systemPackages = with pkgs; [
    treefmt
    nixfmt-rfc-style
    shfmt
    stylua
    nodePackages.prettier
    black
  ];

  home-manager.users.${user0.name} = {
    home.file.".config/treefmt/treefmt.toml".source = ./treefmt.toml;

    programs.fish.functions.treefmt = ''
      if test -f treefmt.toml; or test -f .treefmt.toml
        command treefmt $argv
      else
        command treefmt --config-file ~/.config/treefmt/treefmt.toml --tree-root . $argv
      end
    '';
  };
}
