{
  config,
  globals,
  specialArgs,
  ...
}:

let
  user0 = globals.users 0;
  passwordFile = config.age.secrets.smb-user0.path;
  mountPoint = "/Users/${user0.name}/smb";
in
{
  age.secrets.smb-user0 = {
    file = "${specialArgs.secretsCommon}/smb-user0.age";
    owner = user0.name;
    group = "staff";
    mode = "0400";
  };

  system.defaults.CustomUserPreferences = {
    "com.apple.desktopservices" = {
      DSDontWriteNetworkStores = true;
      DSDontWriteUSBStores = true;
    };
  };

  home-manager.users.${user0.name} = {
    home.file.".local/bin/mount-smb" = {
      executable = true;
      text = ''
        #!/bin/bash
        set -euo pipefail

        USERNAME="${user0.name}"
        PASSWORD=$(< "${passwordFile}")
        MOUNT_POINT="${mountPoint}"

        mkdir -p "$MOUNT_POINT"
        mount_smbfs "//$USERNAME:$PASSWORD@10.0.4.32/$USERNAME" "$MOUNT_POINT"
      '';
    };

    launchd.agents."mount-smb-${user0.name}" = {
      enable = true;
      config = {
        ProgramArguments = [ "/Users/${user0.name}/.local/bin/mount-smb" ];
        RunAtLoad = true;
        KeepAlive = {
          SuccessfulExit = false;
        };
        StandardOutPath = "/tmp/mount-smb-${user0.name}.out";
        StandardErrorPath = "/tmp/mount-smb-${user0.name}.err";
        WatchPaths = [
          "/Library/Preferences/SystemConfiguration/NetworkInterfaces.plist"
          "/Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist"
        ];
      };
    };
  };
}
