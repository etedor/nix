{
  globals,
  lib,
  ...
}:

let
  user0 = globals.users 0;
  user1 = globals.users 1;
  users = [
    user0.name
    user1.name
  ];

  mkDisplayPlacerAgent = user: {
    launchd = {
      enable = true;

      agents.displayplacer = {
        enable = true;

        config = {
          ProgramArguments = [
            "/opt/homebrew/bin/displayplacer"
            "id:22B6CEF9-D7CB-4DE8-9AA8-1EE291F4A7FF"
            "res:2560x1440"
            "hz:60"
            "color_depth:8"
            "enabled:true"
            "scaling:on"
            "origin:(0,0)"
            "degree:0"
          ];
          RunAtLoad = true;
          StartInterval = 60;
          LimitLoadToSessionType = "Aqua";
          StandardOutPath = "/tmp/displayplacer-${user}.out";
          StandardErrorPath = "/tmp/displayplacer-${user}.err";
        };
      };
    };
  };
in
{
  homebrew.brews = [ "displayplacer" ];
  home-manager.users = lib.genAttrs users mkDisplayPlacerAgent;
}
