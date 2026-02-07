{
  config,
  globals,
  ...
}:

let
  rt-ggz = globals.routers.rt-ggz;
  rt-ggz2 = globals.routers.rt-ggz2;
  rt-sea = globals.routers.rt-sea;

  rmRfc1918 = config.et42.router.frr.rfc1918RouteMap;
in
{
  imports = [ ./pbr.nix ];

  et42.router.frr = {
    enable = true;

    bgpConfig = {
      asn = rt-ggz2.localAs;
      routerId = rt-ggz2.interfaces.lo0;
      neighbors = [
        {
          ip = "10.100.0.2";
          remoteAs = rt-sea.localAs;
          routeMapIn = null;
          routeMapOut = null;
        }
        {
          ip = rt-ggz.interfaces.xc0; # rt-ggz xc0
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
              routeMap = rmRfc1918;
            }
            {
              protocol = "static";
              routeMap = rmRfc1918;
            }
          ];
          neighbors = [
            {
              ip = "10.100.0.2";
              remoteAs = rt-sea.localAs;
              routeMapIn = rmRfc1918;
              routeMapOut = rmRfc1918;
            }
            {
              ip = rt-ggz.interfaces.xc0;
              remoteAs = rt-ggz.localAs;
              routeMapIn = rmRfc1918;
              routeMapOut = rmRfc1918;
            }
          ];
        }
      ];
    };
  };
}
