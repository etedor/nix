{
  config,
  globals,
  specialArgs,
  ...
}:

let
  rt-sea = globals.routers.rt-sea;
  lo0 = rt-sea.interfaces.lo0;

  rt-sea-unbound = "${rt-sea.interfaces.lo0}:5353";
in
{
  et42.router.dns.blocky = {
    enable = true;
    listenAddress = [
      lo0
      globals.anycast.dns
    ];

    upstream = {
      servers = [
        rt-sea-unbound
      ];
      timeout = "500ms";
    };

    customDNS =
      let
        hostname = config.networking.hostName;
        fqdn = "${hostname}.${globals.zones.home}";
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
    tsigKeyFile = config.age.secrets.knot-tsig-key.path;
  };

  age.secrets.knot-tsig-key = {
    file = "${specialArgs.secretsRole}/knot-tsig-key.age";
    owner = "knot";
    mode = "0400";
  };

  # advertise the anycast VIP only while this VPS can recurse from roots
  et42.router.anycastHealth = {
    enable = true;
    probe = "roots";
  };
}
