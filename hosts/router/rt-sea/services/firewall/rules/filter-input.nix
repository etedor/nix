{
  config,
  globals,
  ...
}:

let
  wg = config.et42.router.wireguard;

  net = globals.networks;

  rt-sea = globals.routers.rt-sea;
  zone = rt-sea.zones;
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
      name = "bgp";
      iifs = zone.p2p;
      dpts = [ 179 ];
      action = "accept";
      proto = "tcp";
    }

    {
      name = "ssh";
      sips = net.admin;
      dips = [ rt-sea.interfaces.lo0 ];
      dpts = [ 22 ];
      action = "accept";
      proto = "tcp";
    }

    {
      name = "dns";
      sips = net.rfc1918;
      dips = [ rt-sea.interfaces.lo0 ];
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
