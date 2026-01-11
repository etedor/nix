{
  config,
  globals,
  ...
}:

let
  rt-ggz = globals.routers.rt-ggz;
  rt-sea = globals.routers.rt-sea;
  lo0 = rt-sea.interfaces.lo0;

  rt-ggz-knot = "${rt-ggz.interfaces.lo0}:5354";
  rt-sea-unbound = "${rt-sea.interfaces.lo0}:5353";
in
{
  et42.router.dns.blocky = {
    enable = true;
    listenAddress = "${lo0}:53";

    upstream = {
      servers = [ rt-sea-unbound ];
      timeout = "500ms";
    };

    conditionalMapping = {
      "in-addr.arpa" = rt-ggz-knot;
      "${globals.zone}" = rt-ggz-knot;
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
    listenAddress = lo0;
  };
}
