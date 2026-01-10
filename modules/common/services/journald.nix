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
        rateLimitBurst = 0;
        extraConfig = "SystemMaxUse=256M";
      };
    };
  };

  darwin = {

  };
}
