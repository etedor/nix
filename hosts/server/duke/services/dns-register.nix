{
  config,
  globals,
  specialArgs,
  ...
}:

{
  et42.server.dnsRegister = {
    enable = true;
    zone = globals.zone;
    address = globals.hosts.duke.ip;
    tsigKeyFile = config.age.secrets.nsupdate-tsig-key.path;
  };

  age.secrets.nsupdate-tsig-key.file = "${specialArgs.secretsRole}/nsupdate-tsig-key.age";
}
