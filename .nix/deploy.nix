{
  self,
  deploy-rs,
  globals,
}:

let
  zone = globals.zone;
  user0 = (globals.users 0).name;

  mkNixosNode =
    name:
    {
      remoteBuild ? true,
      hostname ? "${name}.${zone}",
    }:
    {
      inherit hostname;
      sshOpts = [ "-A" ]; # forward SSH agent for sudo auth
      profiles.system = {
        sshUser = user0;
        user = "root";
        sudo = "sudo -u";
        path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.${name};
        inherit remoteBuild;
      };
    };

  mkDarwinNode =
    name:
    {
      hostname ? "${name}.${zone}",
      magicRollback ? true,
      interactiveSudo ? true,
    }:
    {
      inherit hostname;
      sshOpts = [ "-A" ]; # forward SSH agent for sudo auth
      profiles.system = {
        sshUser = user0;
        user = "root";
        sudo = "PATH=/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:$PATH sudo -S -u";
        path = deploy-rs.lib.aarch64-darwin.activate.darwin self.darwinConfigurations.${name};
        inherit magicRollback interactiveSudo;
      };
    };
in
{
  duke = mkNixosNode "duke" { };
  rt-ggz = mkNixosNode "rt-ggz" { };
  rt-sea = mkNixosNode "rt-sea" { remoteBuild = false; };

  garage = mkDarwinNode "garage" {
    hostname = "10.0.8.33"; # TODO
  };
  machina = mkDarwinNode "machina" {
    hostname = "localhost";
    magicRollback = false;
    interactiveSudo = false;
  };
}
