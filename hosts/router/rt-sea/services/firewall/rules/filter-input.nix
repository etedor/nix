{
  config,
  ...
}:

let
  zoneTrust = [
    "wg0"
    "wg1"
    "wg2"
  ];
  zoneUntrust = [ "ens3" ];

  wg = config.et42.router.wireguard;
  rt-sea = config.et42.router.peers.rt-sea;

  net = config.et42.router.networks;
in
{
  rules = [
    {
      name = "BGP";
      iifs = zoneTrust;
      dpts = [ 179 ];
      action = "accept";
      proto = "tcp";
    }
    {
      name = "SSH";
      iifs = zoneTrust;
      sips = [
        net.ggz.trust3
        net.sea.wg1
      ];
      dips = [ rt-sea.interfaces.lo0 ];
      dpts = [ 22 ];
      action = "accept";
      proto = "tcp";
    }
    {
      name = "WireGuard";
      iifs = zoneUntrust;
      dpts = wg.listenPorts;
      action = "accept";
      proto = "udp";
    }
    {
      name = "DNS";
      iifs = zoneTrust;
      dips = [ rt-sea.interfaces.lo0 ];
      dpts = [
        53
        5353
      ];
      action = "accept";
      proto = "tcp";
    }
    {
      name = "DNS";
      iifs = zoneTrust;
      dips = [ rt-sea.interfaces.lo0 ];
      dpts = [
        53
        5353
      ];
      action = "accept";
      proto = "udp";
    }
  ];
}
