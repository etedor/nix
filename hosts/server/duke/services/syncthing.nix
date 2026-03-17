# per-user syncthing via home-manager systemd user services

{
  config,
  globals,
  specialArgs,
  ...
}:

let
  keys = globals.keys;
  user0 = globals.users 0;
  user1 = globals.users 1;

  syncSettings = {
    options = {
      localAnnounceEnabled = true;
      relaysEnabled = false;
      urAccepted = -1;
    };
  };

  # user0: default ports. user1: offset by 1 to avoid conflicts.
  user0Listen = [ "tcp://:22000" "quic://:22000" ];
  user1Listen = [ "tcp://:22001" "quic://:22001" ];
in
{
  age.secrets = {
    syncthing-user0-cert = {
      file = "${specialArgs.secretsHost}/syncthing-user0-cert.age";
      owner = user0.name;
      mode = "0400";
    };
    syncthing-user0-key = {
      file = "${specialArgs.secretsHost}/syncthing-user0-key.age";
      owner = user0.name;
      mode = "0400";
    };
    syncthing-user1-cert = {
      file = "${specialArgs.secretsHost}/syncthing-user1-cert.age";
      owner = user1.name;
      mode = "0400";
    };
    syncthing-user1-key = {
      file = "${specialArgs.secretsHost}/syncthing-user1-key.age";
      owner = user1.name;
      mode = "0400";
    };
  };

  users.users.${user1.name} = {
    isSystemUser = true;
    group = user1.name;
    home = "/pool0/users/${user1.name}";
    createHome = true;
    shell = "/run/current-system/sw/bin/nologin";
    linger = true;
  };
  users.groups.${user1.name} = { };

  home-manager.users = {
    ${user0.name}.services.syncthing = {
      enable = true;
      cert = config.age.secrets.syncthing-user0-cert.path;
      key = config.age.secrets.syncthing-user0-key.path;
      overrideDevices = true;
      overrideFolders = true;

      settings = syncSettings // {
        options.listenAddresses = user0Listen;
        devices = {
          machina.id = keys.syncthing.machina;
          carbon.id = keys.syncthing.carbon;
          garage-user0.id = keys.syncthing.garage-user0;
        };
        # folders.music = {
        #   path = "/pool0/users/${user0.name}/music";
        #   devices = [ "machina" "carbon" "garage-user0" ];
        #   type = "sendreceive";
        #   fsWatcherEnabled = true;
        # };
      };
    };

    ${user1.name} = {
      home.stateVersion = "24.11";
      services.syncthing = {
        enable = true;
        guiAddress = "127.0.0.1:8385";
        cert = config.age.secrets.syncthing-user1-cert.path;
        key = config.age.secrets.syncthing-user1-key.path;
        overrideDevices = true;
        overrideFolders = true;

        settings = syncSettings // {
          options.listenAddresses = user1Listen;
          devices = {
            garage-user1.id = keys.syncthing.garage-user1;
          };
          folders.user1 = {
            path = "/pool0/users/${user1.name}";
            devices = [ "garage-user1" ];
            type = "sendreceive";
            fsWatcherEnabled = true;
          };
        };
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 22000 22001 ];
    allowedUDPPorts = [ 22000 22001 21027 ];
  };
}
