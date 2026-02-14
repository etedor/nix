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
    subdomains = [
      "ha" "nr" "og" "wifi"
      "pdu1" "pdu2" "pdu3"
      "ups-garage-20a" "ups-office"
      "ai" "n8n"
      "paperless" "rss" "go" "atuin" "tidal"
      "navidrome" "jf" "requests" "nzb" "tv" "movies" "prowl"
    ];
  };

  age.secrets.nsupdate-tsig-key.file = "${specialArgs.secretsHost}/nsupdate-tsig-key.age";
}
