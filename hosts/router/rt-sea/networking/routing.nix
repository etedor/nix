{
  globals,
  ...
}:

let
  net = globals.networks;
  rt-ggz = globals.routers.rt-ggz;
  rt-sea = globals.routers.rt-sea;

  rfc1918PL = "RFC1918_V4";
  rfc1918RM = "RFC1918_V4";
in
{
  et42.router.frr = {
    enable = true;

    staticRoutes = [
      {
        network = net.travel.lan;
        iface = "wg11";
      }
      {
        network = "10.0.0.0/8";
        iface = "blackhole";
      }
      {
        network = "172.16.0.0/12";
        iface = "blackhole";
      }
      {
        network = "192.168.0.0/16";
        iface = "blackhole";
      }
    ];

    prefixLists = [
      {
        name = rfc1918PL;
        seq = 5;
        action = "permit";
        prefix = "10.0.0.0/8";
        ge = 8;
        le = 32;
      }
      {
        name = rfc1918PL;
        seq = 10;
        action = "permit";
        prefix = "172.16.0.0/12";
        ge = 12;
        le = 32;
      }
      {
        name = rfc1918PL;
        seq = 15;
        action = "permit";
        prefix = "192.168.0.0/16";
        ge = 16;
        le = 32;
      }
    ];

    routeMaps = [
      {
        name = rfc1918RM;
        seq = 10;
        action = "permit";
        match = [ "ip address prefix-list ${rfc1918PL}" ];
      }
    ];

    bgpConfig = {
      asn = rt-sea.localAs;
      routerId = rt-sea.interfaces.lo0;

      neighbors = [
        {
          ip = rt-ggz.interfaces.wg0;
          remoteAs = rt-ggz.localAs;
          routeMapIn = null;
          routeMapOut = null;
        }
      ];

      addressFamilies = [
        {
          family = "ipv4 unicast";
          redistribute = [
            {
              protocol = "connected";
              routeMap = rfc1918RM;
            }
            {
              protocol = "static";
              routeMap = rfc1918RM;
            }
          ];
          neighbors = [
            {
              ip = rt-ggz.interfaces.wg0;
              remoteAs = rt-ggz.localAs;
              routeMapIn = rfc1918RM;
              routeMapOut = rfc1918RM;
            }
          ];
        }
      ];
    };
  };
}
