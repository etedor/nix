{
  globals,
  ...
}:

let
  net = globals.networks;
in
{
  rules = [
    {
      name = "BFD";
      proto = "udp";
      dpts = [ 3784 ];
      iifs = [
        "wg0"
        "xc0"
      ];
      action = "accept";
    }

    {
      name = "BGP";
      proto = "tcp";
      dpts = [ 179 ];
      iifs = [
        "wg0"
        "xc0"
      ];
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
      iifs = [ "lan0" ];
      action = "accept";
    }

    {
      name = "SSH";
      proto = "tcp";
      dpts = [ 22 ];
      sips = net.admin;
      action = "accept";
    }
    {
      name = "SSH mgmt";
      proto = "tcp";
      dpts = [ 22 ];
      sips = [ net.ggz2.mgmt ];
      action = "accept";
    }

    {
      name = "DNS";
      proto = [
        "tcp"
        "udp"
      ];
      sips = [ net.ggz2.mgmt ];
      dpts = [
        53
        5354
      ];
      action = "accept";
    }
  ];
}
