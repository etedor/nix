{
  config,
  globals,
  specialArgs,
  ...
}:

let
  user0 = globals.users 0;
  passwordFile = config.age.secrets.smb-user0.path;
  duke = "duke.${globals.zone}";
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
    home.file.".local/bin/mount-duke" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail

        USERNAME="${user0.name}"
        PASSWORD=$(tr -d '\n' < "${passwordFile}")
        SERVER="${duke}"
        MOUNT_BASE="/Users/$USERNAME/Volumes/duke"

        mkdir -p "$MOUNT_BASE/media" "$MOUNT_BASE/$USERNAME"

        # unmount if already mounted
        umount "$MOUNT_BASE/media" 2>/dev/null || true
        umount "$MOUNT_BASE/$USERNAME" 2>/dev/null || true

        mount_smbfs "//$USERNAME:$PASSWORD@$SERVER/media" "$MOUNT_BASE/media"
        mount_smbfs "//$USERNAME:$PASSWORD@$SERVER/$USERNAME" "$MOUNT_BASE/$USERNAME"
      '';
    };

    launchd.agents."mount-duke" = {
      enable = true;
      config = {
        ProgramArguments = [ "/Users/${user0.name}/.local/bin/mount-duke" ];
        RunAtLoad = true;
        KeepAlive = {
          SuccessfulExit = false;
        };
        StandardOutPath = "/tmp/mount-duke.out";
        StandardErrorPath = "/tmp/mount-duke.err";
        WatchPaths = [
          "/Library/Preferences/SystemConfiguration/NetworkInterfaces.plist"
          "/Library/Preferences/SystemConfiguration/com.apple.airport.preferences.plist"
        ];
      };
    };
  };
}
