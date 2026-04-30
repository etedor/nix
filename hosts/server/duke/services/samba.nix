{
  config,
  globals,
  specialArgs,
  ...
}:

let
  user0 = globals.users 0;
in
{
  age.secrets.smb-user0 = {
    file = "${specialArgs.secretsCommon}/smb-user0.age";
    owner = "root";
    mode = "0400";
  };

  system.activationScripts.samba-users = {
    deps = [ "users" ];
    text = ''
      PASSWORD=$(cat ${config.age.secrets.smb-user0.path} | tr -d '\n')
      printf '%s\n%s\n' "$PASSWORD" "$PASSWORD" | \
        ${config.services.samba.package}/bin/smbpasswd -a -s ${user0.name}
    '';
  };

  services.samba = {
    enable = true;
    settings = {
      "${user0.name}" = {
        path = "/pool0/users/${user0.name}";
        "valid users" = [ user0.name ];
        "write list" = [ user0.name ];
        "read only" = "no";
        browseable = "yes";
      };
      media = {
        path = "/pool0/media";
        "valid users" = [ user0.name ];
        "write list" = [ user0.name ];
        "read only" = "yes";
        browseable = "yes";
      };
      paperless_consume = {
        path = "/pool0/paperless/consumption";
        "valid users" = [ "brother" ];
        "write list" = [ "brother" ];
        "read only" = "no";
        browseable = "yes";
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [
      135
      139
      445
    ];
    allowedUDPPorts = [
      137
      138
    ];
  };
}
