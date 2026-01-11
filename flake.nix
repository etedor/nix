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
    deploy-rs.url = "github:serokell/deploy-rs";
    mac-app-util.url = "github:hraban/mac-app-util";
    private.url = "git+ssh://git@github.com/etedor/nix-private";
    quadlet-nix.url = "github:SEIAROTg/quadlet-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,

      agenix,
      darwin,
      deploy-rs,
      home-manager,
      mac-app-util,
      nur,
      private,
      quadlet-nix,
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

      # common modules for nixos hosts
      commonModules = [
        ./modules/common
        agenix.nixosModules.default
        { environment.systemPackages = [ agenix.packages.x86_64-linux.default ]; }
        quadlet-nix.nixosModules.quadlet
        home-manager.nixosModules.home-manager
      ];

      # nixos host builder
      mkHost =
        {
          name,
          system ? "x86_64-linux",
          role,
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules =
            commonModules
            ++ [
              {
                nixpkgs = {
                  inherit overlays;
                  config.allowUnfree = true;
                };
                _module.args.pkgs-unstable = import nixpkgs-unstable {
                  inherit system overlays;
                  config.allowUnfree = true;
                };
              }
              ./hosts/${role}/${name}
            ]
            ++ nixpkgs.lib.optional (role == "router") ./modules/router
            ++ nixpkgs.lib.optional (role == "server") ./modules/server;

          specialArgs = {
            inherit
              inputs
              globals
              overlays
              system
              ;
            secretsCommon = ./secrets/common;
            secretsRole = ./secrets/${role};
            secretsHost = ./secrets/${role}/${name};
            mkModule = mkPlatformModule {
              lib = nixpkgs.lib;
              inherit system;
            };
          };
        };

      # darwin host builder
      mkDarwinHost =
        {
          name,
          system ? "aarch64-darwin",
          role ? "darwin",
        }:
        let
          pkgs = import nixpkgs {
            inherit system overlays;
            config.allowUnfree = true;
          };
          pkgs-unstable = import nixpkgs-unstable {
            inherit system overlays;
            config.allowUnfree = true;
          };
        in
        darwin.lib.darwinSystem {
          inherit system;
          modules = [
            ./modules/common
            agenix.darwinModules.default
            { environment.systemPackages = [ agenix.packages.${system}.default ]; }
            mac-app-util.darwinModules.default
            home-manager.darwinModules.home-manager
            ./hosts/darwin/${name}
            ./modules/darwin
          ];

          specialArgs = {
            inherit
              inputs
              globals
              pkgs
              pkgs-unstable
              overlays
              ;
            secretsCommon = ./secrets/common;
            secretsRole = ./secrets/${role};
            secretsHost = ./secrets/${role}/${name};
            mkModule = mkPlatformModule {
              lib = nixpkgs.lib;
              inherit system;
            };
          };
        };

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
        carbon = mkDarwinHost { name = "carbon"; };
        garage = mkDarwinHost { name = "garage"; };
        machina = mkDarwinHost { name = "machina"; };
      };

      deploy.nodes = import ./.nix/deploy.nix { inherit self deploy-rs globals; };

      checks.x86_64-linux = deploy-rs.lib.x86_64-linux.deployChecks self.deploy;
    };
}
