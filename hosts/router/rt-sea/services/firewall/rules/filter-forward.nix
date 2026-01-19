{
  globals,
  net,
  zone,
  ...
}:

let
  ntp = globals.hosts.ntp;
in
{
  rules = [
    {
      name = "rfc1918 to ntp";
      sips = net.rfc1918;
      dips = [ ntp.ip ];
      dpts = [ 123 ];
      proto = "udp";
      action = "accept";
    }
    {
      name = "peer-admin to p2p";
      iifs = zone.peer-admin;
      oifs = zone.p2p;
      action = "accept";
    }
    {
      name = "p2p to peer-admin";
      iifs = zone.p2p;
      oifs = zone.peer-admin;
      action = "accept";
    }
    {
      name = "peer-admin to internet";
      sips = [ net.sea.wg10 ];
      dips = [ "0.0.0.0/0" ];
      action = "accept";
    }
    {
      name = "peer-family icmp";
      iifs = zone.peer-family;
      proto = "icmp";
      action = "accept";
    }
    {
      name = "icmp to peer-family";
      oifs = zone.peer-family;
      proto = "icmp";
      action = "accept";
    }
  ];
}
