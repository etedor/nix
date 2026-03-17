# syncthing file sync with duke — replaces SMB mounts

{
  config,
  globals,
  specialArgs,
  ...
}:

let
  keys = globals.keys;
  user0 = globals.users 0;

  syncSettings = {
    options = {
      localAnnounceEnabled = true;
      relaysEnabled = false;
      urAccepted = -1;
    };
  };

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
    syncthing-user0-cert = {
      file = "${specialArgs.secretsHost}/syncthing-user0-cert.age";
      owner = user0.name;
      group = "staff";
      mode = "0400";
    };
    syncthing-user0-key = {
      file = "${specialArgs.secretsHost}/syncthing-user0-key.age";
      owner = user0.name;
      group = "staff";
      mode = "0400";
    };
  };

  home-manager.users.${user0.name}.services.syncthing = {
    enable = true;
    cert = config.age.secrets.syncthing-user0-cert.path;
    key = config.age.secrets.syncthing-user0-key.path;
    overrideDevices = true;
    overrideFolders = true;

    settings = syncSettings // {
      devices = {
        duke-user0 = {
          id = keys.syncthing.duke-user0;
          addresses = [ "tcp://${globals.hosts.duke.name}:22000" ];
        };
      };
      # folders.music = {
      #   path = "/Users/${user0.name}/Music/inbox";
      #   devices = [ "duke-user0" ];
      #   type = "sendreceive";
      #   fsWatcherEnabled = true;
      #   ignorePatterns = stignore;
      # };
    };
  };
}
