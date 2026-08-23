{
  config,
  globals,
  specialArgs,
  ...
}:

let
  rt-ggz = globals.routers.rt-ggz;
  things = globals.networks.ggz.things;

  rt-ggz-unbound = "${rt-ggz.interfaces.lo0}:5353";
in
{
  et42.router.dns.blocky = {
    enable = true;
    listenAddress = [
      rt-ggz.interfaces.lo0
      globals.anycast.dns
    ];

    upstream = {
      servers = [
        rt-ggz-unbound
      ];
      timeout = "500ms";
    };

    clientGroupsBlock = {
      default = [
        "default"
        "local"
      ];

      "${things}" = [
        "default"
        "doh"
        "local"
      ];
    };
  };

  et42.router.dns.unbound = {
    enable = true;
    listenAddress = [ rt-ggz.interfaces.lo0 ];
    forwardAddrs = [
      "1.1.1.1@853#cloudflare-dns.com"
      "1.0.0.1@853#cloudflare-dns.com"
    ];
  };

  et42.router.dns.knot = {
    enable = true;
    listenAddress = rt-ggz.interfaces.lo0;
    listenPort = 5354;
    tsigKeyFile = config.age.secrets.knot-tsig-key.path;
  };

  age.secrets.knot-tsig-key = {
    file = "${specialArgs.secretsRole}/knot-tsig-key.age";
    owner = "knot";
    mode = "0400";
  };

  # advertise the anycast VIP only while rt-ggz can resolve via Cloudflare DoT
  et42.router.anycastHealth = {
    enable = true;
    probe = "cloudflare-dot";
  };

  networking = {
    nameservers = [ rt-ggz.interfaces.lo0 ];
    domain = globals.zones.home;
    search = [ globals.zones.home ];
  };
}
