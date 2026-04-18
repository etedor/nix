{
  config,
  specialArgs,
  ...
}:

{
  age.secrets.quadlink = {
    file = "${specialArgs.secretsHost}/quadlink.age";
    mode = "400";
    owner = "quadlink";
    group = "quadlink";
  };

  # config path: /var/lib/quadlink/.quadlink/config.yaml
  services.quadlink = {
    enable = true;
    interval = 30;
    logLevel = "info";
    enableWebui = true;
    webuiHost = "127.0.0.1";
    openFirewall = false;
  };

  users.users.eric.extraGroups = [ "quadlink" ];

  systemd.services.quadlink.environment = {
    QL_CREDENTIALS__FILE = config.age.secrets.quadlink.path;
  };
}
