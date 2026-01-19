{
  net,
  rt-sea,
  wg,
  zone,
  ...
}:

{
  rules = [
    {
      name = "BGP";
      iifs = zone.p2p;
      dpts = [ 179 ];
      action = "accept";
      proto = "tcp";
    }
    {
      name = "SSH from admin";
      iifs = zone.p2p ++ zone.peer-admin;
      sips = [
        net.ggz.trust3
        net.sea.wg10
      ];
      dips = [ rt-sea.interfaces.lo0 ];
      dpts = [ 22 ];
      action = "accept";
      proto = "tcp";
    }
    {
      name = "WireGuard";
      iifs = zone.untrust;
      dpts = wg.listenPorts;
      action = "accept";
      proto = "udp";
    }
    {
      name = "DNS";
      iifs = zone.p2p ++ zone.peer-admin ++ zone.peer-family;
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
      iifs = zone.p2p ++ zone.peer-admin ++ zone.peer-family;
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
