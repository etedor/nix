{
  config,
  globals,
  specialArgs,
  ...
}:

let
  user0 = globals.users 0;
  passwordFile = config.age.secrets.smb-user0.path;
  duke = "duke.${globals.zones.home}";
  mountBase = "/Users/${user0.name}/Volumes/duke";
in
{
  age.secrets.smb-user0 = {
    file = "${specialArgs.secretsCommon}/smb-user0.age";
    owner = "root";
    group = "wheel";
    mode = "0400";
  };

  system.defaults.CustomUserPreferences = {
    "com.apple.desktopservices" = {
      DSDontWriteNetworkStores = true;
      DSDontWriteUSBStores = true;
    };
  };

  # autofs mounts on-demand and handles sleep/wake gracefully
  # automountd can't access keychain, so credentials are templated from agenix
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

  # template auto_duke with credentials from agenix at activation time
  system.activationScripts.postActivation.text = ''
    PASSWORD=$(tr -d '\n' < "${passwordFile}")
    cat > /etc/auto_duke <<EOF
    media           -fstype=smbfs,soft,nodev,nosuid    ://${user0.name}:$PASSWORD@${duke}/media
    ${user0.name}   -fstype=smbfs,soft,nodev,nosuid    ://${user0.name}:$PASSWORD@${duke}/${user0.name}
    EOF
    chmod 600 /etc/auto_duke
    automount -vc 2>/dev/null || true
  '';
}
