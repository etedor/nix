{
  config,
  globals,
  ...
}:

let
  net = globals.networks;
  zone = globals.routers.rt-ggz.zones;
in
{
  rules = [
    {
      name = "bfd";
      proto = "udp";
      dpts = [ 3784 ];
      iifs = zone.p2p;
      action = "accept";
    }

    {
      name = "bgp";
      proto = "tcp";
      dpts = [ 179 ];
      iifs = zone.p2p;
      action = "accept";
    }

    {
      name = "bgp";
      proto = "tcp";
      dpts = [ 179 ];
      iifs = [ "vlan8" ];
      action = "accept";
    }

    {
      name = "ssh";
      proto = "tcp";
      dpts = [ 22 ];
      iifs = zone.p2p;
      action = "accept";
    }

    {
      name = "dhcp";
      proto = "udp";
      dpts = [
        67
        68
      ];
      spts = [
        67
        68
      ];
      iifs = config.et42.router.vlan.names;
      action = "accept";
    }

    {
      name = "ssh";
      proto = "tcp";
      dpts = [ 22 ];
      sips = net.admin;
      action = "accept";
    }
    {
      name = "ssh";
      proto = "tcp";
      dpts = [ 22 ];
      iifs = [ "mgmt0" ];
      sips = [ net.ggz.mgmt ];
      action = "accept";
    }

    {
      name = "dns";
      proto = [
        "tcp"
        "udp"
      ];
      sips = net.rfc1918;
      dpts = [
        53
        5354
      ];
      action = "accept";
    }

    {
      name = "tftp";
      proto = "udp";
      dpts = [ 69 ];
      sips = [ net.ggz.switches ];
      dips = [ net.ggz.tftp ];
      action = "accept";
    }

    {
      name = "igmp";
      proto = "igmp";
      iifs = [
        "vlan8"
        # "vlan10"
      ];
      action = "accept";
    }

    {
      name = "mdns";
      proto = "udp";
      dpts = [ 5353 ];
      iifs = [
        "vlan8"
        # "vlan10"  # not needed without reflection
      ];
      action = "accept";
    }
  ];
}
