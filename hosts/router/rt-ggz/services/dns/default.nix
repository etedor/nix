{
  config,
  globals,
  ...
}:

let
  rt-ggz = globals.routers.rt-ggz;
  rt-sea = globals.routers.rt-sea;
  trust10 = globals.networks.ggz.trust10;

  rt-ggz-nsd = "${rt-ggz.interfaces.lo0}:5354";
  rt-ggz-unbound = "${rt-ggz.interfaces.lo0}:5353";
  rt-sea-unbound = "${rt-sea.interfaces.lo0}:5353";

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

  archiveTlds = [
    "today"
    "fo"
    "is"
    "li"
    "md"
    "ph"
    "vn"
  ];
  quad9 = "9.9.9.9,149.112.112.112";
  mkArchiveMapping =
    tlds:
    builtins.listToAttrs (
      map (tld: {
        name = "archive.${tld}";
        value = quad9;
      }) tlds
    );
in
{
  et42.router.dns.blocky = {
    enable = true;
    listenAddress = "${rt-ggz.interfaces.lo0}:53";

    upstream = {
      servers = [
        rt-sea-unbound
        rt-ggz-unbound
      ];
      timeout = "500ms";
      strategy = "parallel_best";
    };

    conditionalMapping = {
      "in-addr.arpa" = rt-ggz-nsd;
      "${globals.zone}" = rt-ggz-nsd;
    }
    // mkArchiveMapping archiveTlds;

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

      "${trust10}" = [
        "default"
        "doh"
        "local"
      ];
    };
  };

  et42.router.dns.unbound = {
    enable = true;
    listenAddress = rt-ggz.interfaces.lo0;
    forwardAddrs = [
      "1.1.1.1@853#cloudflare-dns.com"
      "1.0.0.1@853#cloudflare-dns.com"
    ];
  };

  et42.router.dns.nsd = {
    enable = true;
    listenAddress = rt-ggz.interfaces.lo0;
    listenPort = 5354;
    domainName = globals.zone;
    reverseZones = reverseZones;
    staticHosts = import ./static-hosts.nix;
  };

  networking = {
    nameservers = [ rt-ggz.interfaces.lo0 ];
    domain = globals.zone;
    search = [ globals.zone ];
  };
}
