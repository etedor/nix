{
  config,
  net,
  ...
}:
{
  rules = [
    {
      name = "BGP";
      proto = "tcp";
      dpts = [ 179 ];
      iifs = [ "wg0" ];
      action = "accept";
    }

    {
      name = "DHCP";
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
      name = "SSH";
      proto = "tcp";
      dpts = [ 22 ];
      sips = [
        net.ggz.trust3
        net.sea.wg1
      ];
      action = "accept";
    }
    {
      name = "SSH";
      proto = "tcp";
      dpts = [ 22 ];
      sips = [ net.ggz.server ];
      action = "accept";
    }
    {
      name = "SSH";
      proto = "tcp";
      dpts = [ 22 ];
      iifs = [ "mgmt0" ];
      sips = [ net.ggz.mgmt ];
      action = "accept";
    }

    {
      name = "DNS";
      proto = "tcp";
      sips = net.rfc1918;
      dpts = [
        53
        5354
      ];
      action = "accept";
    }
    {
      name = "DNS";
      proto = "udp";
      sips = net.rfc1918;
      dpts = [
        53
        5354
      ];
      action = "accept";
    }

    {
      name = "IGMP";
      proto = "igmp";
      iifs = [ "vlan8" ];
      action = "accept";
    }

  ];
}
