{
  globals,
  ...
}:

let
  user0 = globals.users 0;
in
{
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
