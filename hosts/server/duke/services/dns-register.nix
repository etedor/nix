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
    servers = [
      globals.routers.rt-ggz.interfaces.lo0
      globals.routers.rt-sea.interfaces.lo0
      globals.routers.rt-sea2.interfaces.lo0
    ];
    address = globals.hosts.duke.ip;
    tsigKeyFile = config.age.secrets.nsupdate-tsig-key.path;
  };

  age.secrets.nsupdate-tsig-key.file = "${specialArgs.secretsRole}/nsupdate-tsig-key.age";
}
