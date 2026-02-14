{
  config,
  globals,
  specialArgs,
  ...
}:

let
  rt-sea = globals.routers.rt-sea;
  rt-sea2 = globals.routers.rt-sea2;
  lo0 = rt-sea2.interfaces.lo0;

  local-knot = "${lo0}:5354";
  rt-sea-unbound = "${rt-sea.interfaces.lo0}:5353";
  rt-sea2-unbound = "${rt-sea2.interfaces.lo0}:5353";
in
{
  et42.router.dns.blocky = {
    enable = true;
    listenAddress = [
      "${lo0}:53"
      "${globals.anycast.dns}:53"
    ];

    upstream = {
      servers = [
        rt-sea2-unbound
        rt-sea-unbound
      ];
      timeout = "500ms";
    };

    conditionalMapping = {
      "in-addr.arpa" = local-knot;
      "${globals.zone}" = local-knot;
    };

    denylists = {
      default = config.et42.router.dns.blocky.lists.deny.default;
      doh = config.et42.router.dns.blocky.lists.deny.doh;
      local = config.et42.router.dns.blocky.lists.deny.local;
    };

    allowlists = {
      default = config.et42.router.dns.blocky.lists.allow.default;
    };

    clientGroupsBlock = {
      default = [
        "default"
        "local"
      ];
    };

    customDNS =
      let
        hostname = config.networking.hostName;
        fqdn = "${hostname}.${globals.zone}";
      in
      {
        mapping = {
          "${hostname}" = "${lo0}";
          "${fqdn}" = "${lo0}";
        };
      };
  };

  et42.router.dns.unbound = {
    enable = true;
    listenAddress = [ lo0 ];
  };

  et42.router.dns.knot = {
    enable = true;
    listenAddress = lo0;
    listenPort = 5354;
    domainName = globals.zone;
    reverseZones = [
      "2.0.10.in-addr.arpa"
      "4.0.10.in-addr.arpa"
      "8.0.10.in-addr.arpa"
      "9.0.10.in-addr.arpa"
      "10.0.10.in-addr.arpa"
      "11.0.10.in-addr.arpa"
      "16.0.10.in-addr.arpa"
      "32.0.10.in-addr.arpa"
    ];
    tsigKeyFile = config.age.secrets.knot-tsig-key.path;
  };

  age.secrets.knot-tsig-key = {
    file = "${specialArgs.secretsRole}/knot-tsig-key.age";
    owner = "knot";
    mode = "0400";
  };
}
