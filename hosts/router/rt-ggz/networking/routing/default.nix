{
  config,
  globals,
  ...
}:

let
  rt-ggz = globals.routers.rt-ggz;
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
        network = "192.168.100.1/32";
        iface = "wan0";
      }
      {
        network = "192.168.12.1/32";
        iface = "wan1";
      }
    ];

    bgpConfig = {
      asn = rt-ggz.localAs;
      routerId = rt-ggz.interfaces.lo0;
      extraConfig = [ "bgp bestpath as-path multipath-relax" ];
      neighbors = [
        {
          ip = rt-sea.interfaces.wg0;
          remoteAs = rt-sea.localAs;
          routeMapIn = null;
          routeMapOut = null;
        }
        {
          ip = rt-sea2.interfaces.wg0;
          remoteAs = rt-sea2.localAs;
          routeMapIn = null;
          routeMapOut = null;
        }
      ];
      addressFamilies = [
        {
          family = "ipv4 unicast";
          maximumPaths = 2;
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
              ip = rt-sea.interfaces.wg0;
              remoteAs = rt-sea.localAs;
              routeMapIn = rmRfc1918;
              routeMapOut = rmRfc1918;
            }
            {
              ip = rt-sea2.interfaces.wg0;
              remoteAs = rt-sea2.localAs;
              routeMapIn = rmRfc1918;
              routeMapOut = rmRfc1918;
            }
          ];
        }
      ];
    };
  };

  systemd.services."failmon-wan0" = {
    restartTriggers = [ config.services.frr.config ];
  };

  systemd.services."failmon-wan1" = {
    restartTriggers = [ config.services.frr.config ];
  };
}
