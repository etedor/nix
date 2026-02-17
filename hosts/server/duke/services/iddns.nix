{
  config,
  globals,
  specialArgs,
  ...
}:

{
  et42.server.iddns = {
    enable = true;
    zone = globals.zones.home;
    tsigKeyFile = config.age.secrets.nsupdate-tsig-key.path;
  };

  age.secrets.nsupdate-tsig-key.file = "${specialArgs.secretsRole}/nsupdate-tsig-key.age";
}
