# user1 syncthing instance (user0 handled by modules/darwin/syncthing.nix)

{
  config,
  globals,
  specialArgs,
  ...
}:

let
  keys = globals.keys;
  user1 = globals.users 1;

  stignore = [
    "(?d).DS_Store"
    "(?d).Spotlight-V100"
    "(?d).Trashes"
    "(?d)._*"
    "(?d).fseventsd"
    "(?d).TemporaryItems"
  ];
in
{
  age.secrets = {
    syncthing-user1-cert = {
      file = "${specialArgs.secretsHost}/syncthing-user1-cert.age";
      owner = user1.name;
      group = "staff";
      mode = "0400";
    };
    syncthing-user1-key = {
      file = "${specialArgs.secretsHost}/syncthing-user1-key.age";
      owner = user1.name;
      group = "staff";
      mode = "0400";
    };
  };

  home-manager.users.${user1.name}.services.syncthing = {
    enable = true;
    cert = config.age.secrets.syncthing-user1-cert.path;
    key = config.age.secrets.syncthing-user1-key.path;
    overrideDevices = true;
    overrideFolders = true;

    settings = {
      options = {
        localAnnounceEnabled = true;
        relaysEnabled = false;
        urAccepted = -1;
      };
      devices = {
        duke-user1 = {
          id = keys.syncthing.duke-user1;
          addresses = [ "tcp://${globals.hosts.duke.name}:22001" ];
        };
      };
      folders.user1 = {
        path = "/Users/${user1.name}/Sync";
        devices = [ "duke-user1" ];
        type = "sendreceive";
        fsWatcherEnabled = true;
        ignorePatterns = stignore;
      };
    };
  };
}
