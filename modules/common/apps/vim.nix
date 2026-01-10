{
  globals,
  pkgs,
  ...
}:

let
  user0 = globals.users 0;
in
{
  home-manager.users.${user0.name} = {
    programs.vim = {
      enable = true;
      plugins = with pkgs.vimPlugins; [
        vim-airline
        vim-commentary
      ];
      settings = {
        "expandtab" = true;
        "ignorecase" = true;
        "mouse" = "r";
        "number" = true;
        "shiftwidth" = 4;
        "tabstop" = 4;
      };
      extraConfig = ''
        set smartindent
        set autoindent

        noremap <C-_> :Commentary<CR>
        xnoremap <C-_> :Commentary<CR>
        noremap <31> <C-_>
      '';
    };

    programs.fish.interactiveShellInit = ''
      set -x EDITOR vim
      set -x VISUAL vim
    '';
  };
}
