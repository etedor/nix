{
  config,
  globals,
  ...
}:

let
  net = globals.networks;
  rt-ggz = globals.routers.rt-ggz;
  rt-ggz2 = globals.routers.rt-ggz2;
  rt-sea = globals.routers.rt-sea;
  rt-sea2 = globals.routers.rt-sea2;

  rmRfc1918 = config.et42.router.frr.rfc1918RouteMap;
in
{
  imports = [ ./pbr.nix ];

  et42.router.frr = {
    enable = true;

    staticRoutes = [
      {
        network = net.travel.lan;
        iface = "wg11";
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
        {
          ip = rt-ggz2.interfaces.wg0; # rt-ggz2 via wg1
          remoteAs = rt-ggz2.localAs;
          routeMapIn = null;
          routeMapOut = null;
        }
        {
          ip = rt-sea2.interfaces.wg2; # rt-sea2 via wg2
          remoteAs = rt-sea2.localAs;
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
              routeMap = rmRfc1918;
            }
            {
              protocol = "static";
              routeMap = rmRfc1918;
            }
          ];
          neighbors = [
            {
              ip = rt-ggz.interfaces.wg0;
              remoteAs = rt-ggz.localAs;
              routeMapIn = rmRfc1918;
              routeMapOut = rmRfc1918;
            }
            {
              ip = rt-ggz2.interfaces.wg0;
              remoteAs = rt-ggz2.localAs;
              routeMapIn = rmRfc1918;
              routeMapOut = rmRfc1918;
            }
            {
              ip = rt-sea2.interfaces.wg2;
              remoteAs = rt-sea2.localAs;
              routeMapIn = rmRfc1918;
              routeMapOut = rmRfc1918;
            }
          ];
        }
      ];
    };
  };
}
