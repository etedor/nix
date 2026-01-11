{
  globals,
  mkModule,
  ...
}:

let
  ntp = globals.hosts.ntp;
in
mkModule {
  shared = {
    time.timeZone = globals.tz;
  };

  linux = {
    services = {
      timesyncd.enable = false;
      chrony = {
        enable = true;
        servers = [ ntp.name ];
      };
    };
  };

  darwin = {
    system.activationScripts.setNtpServer.text = ''
      systemsetup -setnetworktimeserver ${ntp.name}
    '';

    system.defaults.menuExtraClock = {
      Show24Hour = true;
      ShowSeconds = true;
      ShowDayOfWeek = true;
      ShowDayOfMonth = true;
      ShowDate = 1;
    };
  };
}
