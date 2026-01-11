{
  config,
  globals,
  lib,
  ...
}:

let
  rt-ggz = globals.routers.rt-ggz;
  rt-sea = globals.routers.rt-sea;

  plRfc1918 = "PL-RFC1918_V4";
  rmRfc1918 = "RM-RFC1918_V4";

  pbrMapName = "VPS-RETURN";
  nhgName = "VPS-WG";
in
{
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

      {
        network = "192.168.100.1/32";
        iface = "wan0";
      }
      {
        network = "192.168.12.1/32";
        iface = "wan1";
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
      asn = rt-ggz.localAs;
      routerId = rt-ggz.interfaces.lo0;
      neighbors = [
        {
          ip = rt-sea.interfaces.wg0;
          remoteAs = rt-sea.localAs;
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
              ip = rt-sea.interfaces.wg0;
              remoteAs = rt-sea.localAs;
              routeMapIn = rmRfc1918;
              routeMapOut = rmRfc1918;
            }
          ];
        }
      ];
    };
  };

  et42.router.nftables = {
    extraManglePreRoutingRules = lib.mkBefore [
      {
        name = "restore-conntrack-mark-for-public";
        expr = "ct mark & 0x10 == 0x10 ip daddr != $RFC_1918";
        action = "meta mark set 0x10";
      }
    ];
    extraMangleForwardRules = [
      {
        name = "mark-internet-via-wg";
        expr = "iifname wg0 ip saddr != $RFC_1918 ct state new";
        action = "ct mark set (ct mark & 0xff00000f | 0x10)"; # preserve DSCP bits (31-24) and set PBR routing bit (4)
      }
    ];
  };

  services.frr = {
    pbrd.enable = true;
    config = ''
      nexthop-group ${nhgName}
        nexthop ${rt-sea.interfaces.wg0}
      !
      pbr-map ${pbrMapName} seq 10
        match mark 16
        set nexthop-group ${nhgName}
      !
      interface vlan4
        pbr-policy ${pbrMapName}
    '';
  };

  systemd.services."failmon-wan0" = {
    restartTriggers = [ config.services.frr.config ];
  };

  systemd.services."failmon-wan1" = {
    restartTriggers = [ config.services.frr.config ];
  };
}
