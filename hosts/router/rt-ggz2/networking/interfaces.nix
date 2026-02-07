{
  config,
  globals,
  ...
}:

let
  rt-ggz2 = globals.routers.rt-ggz2;
  vlanNames = config.et42.router.vlan.names;
in
{
  systemd.network = {
    netdevs = {
      "00-lo0" = {
        netdevConfig = {
          Name = "lo0";
          Kind = "dummy";
        };
      };
    };

    networks = {
      "00-lo0" = {
        matchConfig.Name = "lo0";
        networkConfig = {
          Address = [ "${rt-ggz2.interfaces.lo0}/32" ];
          LinkLocalAddressing = "no";
        };
        linkConfig.RequiredForOnline = "no";
      };

      # cross-connect to rt-ggz (1G Ethernet)
      "10-xc0" = {
        matchConfig.Name = "xc0";
        networkConfig = {
          Address = [ "${rt-ggz2.interfaces.xc0}/31" ];
          DHCP = "no";
        };
      };

      # trunk port carrying VLANs
      "20-lan0" = {
        matchConfig.Name = "lan0";
        vlan = vlanNames;
        linkConfig.RequiredForOnline = "yes";
      };

      # 5G/LTE WAN -- higher metric so tunnels/xc0 are preferred
      "11-wan0" = {
        matchConfig.Name = "wan0";
        networkConfig.DHCP = "yes";
        dhcpV4Config.RouteMetric = 512;
      };
      "12-ifb4wan0" = {
        matchConfig.Name = "ifb4wan0";
        linkConfig = {
          Multicast = false;
          RequiredForOnline = "no";
        };
      };
    };
  };
}
