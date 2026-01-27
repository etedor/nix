{
  globals,
  ...
}:

let
  user0 = globals.users 0;
in
{
  home-manager.users.${user0.name} = {
    programs.fish.loginShellInit = ''
      fish_add_path --move --prepend --path /opt/homebrew/bin
      fish_add_path --move --prepend --path /opt/homebrew/sbin
    '';
  };

  environment.variables.HOMEBREW_NO_ANALYTICS = "1";
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
    };

    casks = [
      "1password"
      "pika"
      "signal"
      "sonos"
      "spotify"
      "wireshark"
    ];

    masApps = {
      Amperfy = 1530145038;
      Amphetamine = 937984704;
      QuadStream = 1051358039;
      UpNote = 1398373917;
      WireGuard = 1451685025;
    };
  };
}
