{
  config,
  globals,
  ...
}:

let
  rt-ggz = globals.routers.rt-ggz;
  rt-ggz2 = globals.routers.rt-ggz2;

  rt-ggz2-knot = "${rt-ggz2.interfaces.lo0}:5354";
  rt-ggz2-unbound = "${rt-ggz2.interfaces.lo0}:5353";
  rt-ggz-unbound = "${rt-ggz.interfaces.lo0}:5353";

  mgmtZone = "et42.management";

  reverseZones = [
    "200.1.10.in-addr.arpa"
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
    listenAddress = [ "${rt-ggz2.interfaces.lo0}:53" ];

    upstream = {
      servers = [
        rt-ggz2-unbound
        rt-ggz-unbound
      ];
      timeout = "500ms";
      strategy = "parallel_best";
    };

    conditionalMapping = {
      "${mgmtZone}" = rt-ggz2-knot;
      "200.1.10.in-addr.arpa" = rt-ggz2-knot;
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
    };
  };

  et42.router.dns.unbound = {
    enable = true;
    listenAddress = [ rt-ggz2.interfaces.lo0 ];
    forwardAddrs = [
      "1.1.1.1@853#cloudflare-dns.com"
      "1.0.0.1@853#cloudflare-dns.com"
    ];
  };

  et42.router.dns.knot = {
    enable = true;
    listenAddress = rt-ggz2.interfaces.lo0;
    listenPort = 5354;
    domainName = mgmtZone;
    reverseZones = reverseZones;
    staticHosts = import ./static-hosts.nix { inherit globals; };
  };

  networking = {
    nameservers = [ rt-ggz2.interfaces.lo0 ];
    domain = mgmtZone;
    search = [ mgmtZone ];
  };
}
