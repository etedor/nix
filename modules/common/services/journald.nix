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
  };

  darwin = {

  };
}
