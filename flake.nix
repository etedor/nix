{
  description = "Darwin and NixOS Configurations";

  inputs = {
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin"; # -darwin branch ensures packages work on both nixos and macOS hosts
    nur.url = "github:nix-community/NUR";

    agenix.url = "github:ryantm/agenix";
    darwin-workflow.url = "github:etedor/nix-darwin-workflow";
    deploy-rs.url = "github:serokell/deploy-rs";
    mac-app-util.url = "github:hraban/mac-app-util";
    private.url = "git+ssh://git@github.com/etedor/nix-private";
    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";
    quadlink.url = "github:etedor/quadlink";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,

      agenix,
      darwin,
      darwin-workflow,
      deploy-rs,
      home-manager,
      mac-app-util,
      nur,
      private,
      quadlet-nix,
      quadlink,
      ...
    }@inputs:
    let
      inherit (import ./.nix/globals.nix { inherit private; }) globals;

      overlays = [ nur.overlays.default ];

      # platform-aware module factory for shared/linux/darwin configs
      mkPlatformModule =
        { lib, system }:
        {
          shared ? { },
          linux ? { },
          darwin ? { },
        }:
        let
          merge =
            a: b:
            lib.foldlAttrs (
              acc: key: val:
              let
                aVal = acc.${key} or null;
              in
              acc
              // {
                ${key} =
                  if builtins.isAttrs aVal && builtins.isAttrs val then
                    merge aVal val
                  else if builtins.isList aVal && builtins.isList val then
                    aVal ++ val
                  else
                    val;
              }
            ) a b;

          platform =
            if system == "x86_64-linux" || system == "aarch64-linux" then
              linux
            else if system == "x86_64-darwin" || system == "aarch64-darwin" then
              darwin
            else
              { };
        in
        merge shared platform;

      # unified host builder
      mkHost =
        {
          name,
          role,
          system ? if role == "darwin" then "aarch64-darwin" else "x86_64-linux",
        }:
        let
          isDarwin = role == "darwin";
          secondsPerYear = 31556952;
          currentYear = 1970 + (nixpkgs.lastModified / secondsPerYear);

          pkgs = import nixpkgs {
            inherit system overlays;
            config.allowUnfree = true;
          };

          pkgs-unstable = import nixpkgs-unstable {
            inherit system overlays;
            config.allowUnfree = true;
          };

          platformModules =
            if isDarwin then
              [
                agenix.darwinModules.default
                { environment.systemPackages = [ agenix.packages.${system}.default ]; }
                darwin-workflow.darwinModules.default
                mac-app-util.darwinModules.default
                home-manager.darwinModules.home-manager
                ./modules/darwin
              ]
            else
              [
                {
                  nixpkgs = {
                    inherit overlays;
                    config.allowUnfree = true;
                  };
                  _module.args.pkgs-unstable = pkgs-unstable;
                }
                agenix.nixosModules.default
                { environment.systemPackages = [ agenix.packages.${system}.default ]; }
                quadlet-nix.nixosModules.quadlet
                quadlink.nixosModules.default
                home-manager.nixosModules.home-manager
              ];

          roleModules =
            if isDarwin then
              [ ]
            else
              nixpkgs.lib.optional (role == "router") ./modules/router
              ++ nixpkgs.lib.optional (role == "server") ./modules/server;

          modules =
            [ ./modules/common ./hosts/${role}/${name} ]
            ++ platformModules
            ++ roleModules;

          specialArgs =
            {
              inherit inputs globals overlays system;
              inherit currentYear;
              secretsCommon = ./secrets/common;
              secretsRole = ./secrets/${role};
              secretsHost = ./secrets/${role}/${name};
              mkModule = mkPlatformModule {
                lib = nixpkgs.lib;
                inherit system;
              };
            }
            // (if isDarwin then { inherit pkgs pkgs-unstable; } else { });
        in
        if isDarwin then
          darwin.lib.darwinSystem { inherit system modules specialArgs; }
        else
          nixpkgs.lib.nixosSystem { inherit system modules specialArgs; };

    in
    {
      nixosConfigurations = {
        duke = mkHost {
          name = "duke";
          role = "server";
        };
        rt-ggz = mkHost {
          name = "rt-ggz";
          role = "router";
        };
        rt-sea = mkHost {
          name = "rt-sea";
          role = "router";
        };
      };

      darwinConfigurations = {
        carbon = mkHost { name = "carbon"; role = "darwin"; };
        garage = mkHost { name = "garage"; role = "darwin"; };
        machina = mkHost { name = "machina"; role = "darwin"; };
      };

      deploy.nodes = import ./.nix/deploy.nix { inherit self deploy-rs globals; };

      checks.x86_64-linux = deploy-rs.lib.x86_64-linux.deployChecks self.deploy;
    };
}
