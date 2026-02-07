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
      name = "bfd";
      proto = "udp";
      dpts = [ 3784 ];
      iifs = [
        "wg0"
        "xc0"
      ];
      action = "accept";
    }

    {
      name = "bgp";
      proto = "tcp";
      dpts = [ 179 ];
      iifs = [
        "wg0"
        "xc0"
      ];
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
      iifs = [ "lan0" ];
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
      name = "ssh mgmt";
      proto = "tcp";
      dpts = [ 22 ];
      sips = [ net.ggz2.mgmt ];
      action = "accept";
    }

    {
      name = "dns";
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
