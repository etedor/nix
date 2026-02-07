{
  config,
  globals,
  ...
}:

let
  wg = config.et42.router.wireguard;

  net = globals.networks;

  rt-sea2 = globals.routers.rt-sea2;
  zone = rt-sea2.zones;
in
{
  rules = [
    {
      name = "wireguard";
      iifs = zone.untrust;
      dpts = wg.listenPorts;
      action = "accept";
      proto = "udp";
    }

    {
      name = "bfd";
      iifs = zone.p2p;
      dpts = [ 3784 ];
      action = "accept";
      proto = "udp";
    }

    {
      name = "bgp";
      iifs = zone.p2p;
      dpts = [ 179 ];
      action = "accept";
      proto = "tcp";
    }

    {
      name = "ssh";
      iifs = zone.p2p;
      dpts = [ 22 ];
      action = "accept";
      proto = "tcp";
    }

    {
      name = "ssh";
      sips = net.admin;
      dips = [ rt-sea2.interfaces.lo0 ];
      dpts = [ 22 ];
      action = "accept";
      proto = "tcp";
    }

    {
      name = "dns";
      sips = net.rfc1918;
      dips = [ rt-sea2.interfaces.lo0 globals.anycast.dns ];
      dpts = [
        53
        5353
      ];
      proto = [
        "tcp"
        "udp"
      ];
      action = "accept";
    }
  ];
}
