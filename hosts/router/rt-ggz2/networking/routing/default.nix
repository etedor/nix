{
  globals,
  ...
}:

let
  rt-ggz = globals.routers.rt-ggz;
  rt-ggz2 = globals.routers.rt-ggz2;
  rt-sea = globals.routers.rt-sea;

  plRfc1918 = "PL-RFC1918_V4";
  rmRfc1918 = "RM-RFC1918_V4";
in
{
  imports = [ ./pbr.nix ];

  et42.router.frr = {
    enable = true;

    staticRoutes = [
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
        name = plRfc1918;
        seq = 5;
        action = "permit";
        prefix = "10.0.0.0/8";
        ge = 8;
        le = 32;
      }
      {
        name = plRfc1918;
        seq = 10;
        action = "permit";
        prefix = "172.16.0.0/12";
        ge = 12;
        le = 32;
      }
      {
        name = plRfc1918;
        seq = 15;
        action = "permit";
        prefix = "192.168.0.0/16";
        ge = 16;
        le = 32;
      }
    ];

    routeMaps = [
      {
        name = rmRfc1918;
        seq = 10;
        action = "permit";
        match = [ "ip address prefix-list ${plRfc1918}" ];
      }
    ];

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
