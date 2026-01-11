{
  globals,
  inputs,
  lib,
  mkModule,
  ...
}:
let
  user0 = globals.users 0;
  homeStateVersion = "25.11";
in
{
  imports = [
    ./apps
    ./atuin.nix
    ./locale.nix
    ./services
    ./shell
    ./users.nix
  ];
  config = mkModule {
    shared = {
      nix = {
        gc = {
          automatic = true;
          options = "--delete-older-than 14d";
        };
        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          trusted-users = [
            user0.name
          ];
          min-free = 1 * 1024 * 1024 * 1024;
          max-free = 5 * 1024 * 1024 * 1024;
          keep-outputs = false;
          keep-derivations = false;
          download-buffer-size = 128 * 1024 * 1024; # 128MB
        };
        optimise.automatic = true;
      };
    };
    linux = {
      age.identityPaths = lib.mkOptionDefault [
        "/home/${user0.name}/.ssh/id_ed25519"
      ];
      nix.gc.dates = "Sun *-*-* 01:00:00";
      system.rebuild.enableNg = true;
      system.autoUpgrade = {
        enable = true;
        dates = "02:00";
        randomizedDelaySec = "45min";
        flags = [
          "--update-input"
          "nixpkgs"
          "-L"
        ];
        flake = inputs.self.outPath;
      };
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
      };
    };
    darwin = {
      age.identityPaths = lib.mkOptionDefault [
        "/Users/${user0.name}/.ssh/id_ed25519"
      ];
      nix.gc.interval = {
        Hour = 1;
        Minute = 0;
        Weekday = 0;
      };
      system.primaryUser = user0.name;
      system.stateVersion = 5;
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "bak";
        users.${user0.name}.home.stateVersion = homeStateVersion;
      };
      system.defaults.WindowManager = {
        EnableTiledWindowMargins = true;
        StandardHideWidgets = true;
        StageManagerHideWidgets = true;
      };
    };
  };
}
