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
    services.ollama = {
      enable = true;
      host = "127.0.0.1";
      port = 11434;
      environmentVariables = {
        OLLAMA_LLM_LIBRARY = "metal";
      };
    };

    home.packages = with pkgs; [
      # llm
      aichat # llm cli (pipe to/from commands)
      oterm # tui for ollama

      # containers
      orbstack
    ];

    # aichat config
    home.file."Library/Application Support/aichat/config.yaml".source = ./aichat.yml;

    # open-webui via docker-compose (orbstack)
    # start: docker compose -f ~/.config/containers/open-webui/compose.yml up -d
    home.file.".config/containers/open-webui/compose.yml".source = ./open-webui.compose.yml;
  };
}
