{
  globals,
  pkgs,
  ...
}:

let
  user0 = globals.users 0;
in
{
  users.users."${user0.name}" = {
    packages = with pkgs; [
      ripgrep
      ugrep
    ];
  };

  home-manager.users.${user0.name} = {
    programs.atuin = {
      enable = true;
      enableFishIntegration = true;
      flags = [ "--disable-up-arrow" ];
    };

    programs.bat = {
      enable = true;
    };
    programs.btop = {
      enable = true;
      settings = {
        color_theme = "TTY";
        theme_background = false;
      };
    };
    programs.lsd = {
      enable = true;
    };
    programs.zoxide = {
      enable = true;
      enableFishIntegration = true;
    };

    programs.fish = {
      shellAliases = {
        cat = "bat --plain";
        cd = "z";
        grep = "ug";
        top = "btop";
        tree = "lsd --tree";
      };
    };
  };
}
