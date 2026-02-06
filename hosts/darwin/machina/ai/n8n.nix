# n8n workflow automation with local ollama integration
{ pkgs, ... }:
{
  launchd.user.agents.n8n = {
    serviceConfig = {
      ProgramArguments = [ "${pkgs.n8n}/bin/n8n" ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/tmp/n8n.log";
      StandardErrorPath = "/tmp/n8n.err";
    };
  };
}
