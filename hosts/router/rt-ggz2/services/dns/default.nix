{
  globals,
  ...
}:

let
  rt-ggz = globals.routers.rt-ggz;
  rt-ggz2 = globals.routers.rt-ggz2;

  mgmtZone = globals.zones.mgmt;

  rt-ggz2-unbound = "${rt-ggz2.interfaces.lo0}:5353";
  rt-ggz-unbound = "${rt-ggz.interfaces.lo0}:5353";
in
{
  et42.router.dns.blocky = {
    enable = true;
    listenAddress = [ rt-ggz2.interfaces.lo0 ];

    upstream = {
      servers = [
        rt-ggz2-unbound
        rt-ggz-unbound
      ];
      timeout = "500ms";
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
  };

  networking = {
    nameservers = [ rt-ggz2.interfaces.lo0 ];
    domain = mgmtZone;
    search = [ mgmtZone ];
  };
}
