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
  mountBase = "/Users/${user0.name}/Volumes/duke";
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

  # autofs mounts on-demand and handles sleep/wake gracefully
  environment.etc."auto_master".text = ''
    #
    # Automounter master map
    #
    +auto_master
    /home                     auto_home       -nobrowse,nosuid
    /Network/Servers          -fstab
    /-                        -static
    ${mountBase}              auto_duke       -nobrowse,nosuid
  '';

  environment.etc."auto_duke".text = ''
    # SMB mounts for duke - credentials from Keychain
    media           -fstype=smbfs,soft,nodev,nosuid    ://${duke}/media
    ${user0.name}   -fstype=smbfs,soft,nodev,nosuid    ://${duke}/${user0.name}
  '';

  # bootstrap keychain credentials from agenix secret (per-share entries)
  home-manager.users.${user0.name} = {
    home.file.".local/bin/keychain-smb-duke" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        PASSWORD="$(tr -d '\n' < "${passwordFile}")"

        # add keychain entry for each share (path is required for mount_smbfs)
        for share in media ${user0.name}; do
          security add-internet-password \
            -a "${user0.name}" \
            -s "${duke}" \
            -p "$share" \
            -D "Network Password" \
            -r "smb " \
            -w "$PASSWORD" \
            -U \
            ~/Library/Keychains/login.keychain-db 2>/dev/null || true
        done
      '';
    };

    launchd.agents."keychain-smb-duke" = {
      enable = true;
      config = {
        ProgramArguments = [ "/Users/${user0.name}/.local/bin/keychain-smb-duke" ];
        RunAtLoad = true;
      };
    };
  };
}
