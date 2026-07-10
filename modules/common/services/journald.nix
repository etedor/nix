{
  mkModule,
  ...
}:

mkModule {
  shared = {

  };

  linux = {
    services = {
      journald = {
        # loose per-unit backstop against a runaway logger (drops on exceed)
        rateLimitInterval = "30s";
        rateLimitBurst = 10000;
        extraConfig = "SystemMaxUse=256M";
      };
    };

    # RAM-backed journal namespace for chatty services; opt in per-host with
    # LogNamespace = "volatile", read via `journalctl --namespace=volatile`
    environment.etc."systemd/journald@volatile.conf".text = ''
      [Journal]
      Storage=volatile
      RuntimeMaxUse=64M
    '';
  };

  darwin = {

  };
}
