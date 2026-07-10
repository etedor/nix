{
  mkModule,
  ...
}:

mkModule {
  shared = { };

  linux = {
    # nsncd's socket handoff doesn't survive a switch-to-configuration restart:
    # bouncing it mid-switch leaves dbus-broker's NSS lookups blocking on a dead
    # socket until the 90s reload timeout, which fails the whole switch and rolls
    # back the deploy. keep it up across switches (as NixOS already does for
    # logind); NSS/user config here is static and refreshes on reboot.
    systemd.services.nscd.restartIfChanged = false;
  };

  darwin = { };
}
