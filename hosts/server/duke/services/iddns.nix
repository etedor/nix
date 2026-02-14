{
  config,
  globals,
  specialArgs,
  ...
}:

{
  et42.server.iddns = {
    enable = true;
    zone = globals.zone;
    tsigKeyFile = config.age.secrets.nsupdate-tsig-key.path;
  };

  age.secrets.nsupdate-tsig-key.file = "${specialArgs.secretsRole}/nsupdate-tsig-key.age";
}
