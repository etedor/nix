{
  config,
  globals,
  ...
}:

let
  rt-ggz = config.et42.router.peers.rt-ggz;
  vlanNames = config.et42.router.vlan.names;
in
{
  config = {
    systemd.network = {
      links = {
        "10-mgmt0" = {
          matchConfig.PermanentMACAddress = "00:f0:cb:fe:c3:23";
          linkConfig = {
            Name = "mgmt0";
            MTUBytes = "1500";
          };
        };

        "11-wan0" = {
          matchConfig.PermanentMACAddress = "00:f0:cb:fe:c3:24";
          linkConfig = {
            Name = "wan0";
            MTUBytes = "1500";
          };

          extraConfig = ''
            [Coalesce]
            RxUsecs=0
            TxUsecs=0
          '';
        };
        "12-wan1" = {
          matchConfig.PermanentMACAddress = "00:f0:cb:fe:c3:25";
          linkConfig = {
            Name = "wan1";
            MTUBytes = "1500";
          };
        };

        "20-lan0" = {
          matchConfig.PermanentMACAddress = "ec:0d:9a:36:fa:ee";
          linkConfig = {
            Name = "lan0";
            MTUBytes = globals.jumbo;
          };
        };
        "21-lan1" = {
          matchConfig.PermanentMACAddress = "ec:0d:9a:36:fa:ef";
          linkConfig = {
            Name = "lan1";
            MTUBytes = globals.jumbo;
          };
        };
      };

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
            Address = [ "${rt-ggz.interfaces.lo0}/32" ];
            LinkLocalAddressing = "no";
          };
          linkConfig.RequiredForOnline = "no";
        };

        "10-mgmt0" = {
          matchConfig.Name = "mgmt0";
          networkConfig = {
            Address = [ "192.168.0.32/24" ];
            DHCP = "no";
          };
        };

        "11-wan0" = {
          matchConfig.Name = "wan0";
          networkConfig.DHCP = "yes";
          dhcpV4Config.RouteMetric = 256;
        };
        "12-ifb4wan0" = {
          matchConfig.Name = "ifb4wan0";
          linkConfig = {
            Multicast = false;
            RequiredForOnline = "no";
          };
        };

        "13-wan1" = {
          matchConfig.Name = "wan1";
          networkConfig.DHCP = "yes";
          dhcpV4Config.RouteMetric = 512;
        };
        "14-ifb4wan1" = {
          matchConfig.Name = "ifb4wan1";
          linkConfig = {
            Multicast = false;
            RequiredForOnline = "no";
          };
        };

        "20-lan0" = {
          matchConfig.Name = "lan0";
          vlan = vlanNames;
          linkConfig.RequiredForOnline = "yes";
        };

        "21-lan1" = {
          matchConfig.Name = "lan1";
          linkConfig.RequiredForOnline = "yes";
        };
      };
    };
  };
}
