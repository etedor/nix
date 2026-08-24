{
  globals,
  ...
}:

let
  rt-sea2 = globals.routers.rt-sea2;
in
{
  imports = [
    ./tuning.nix
    ./routing
    ./wireguard.nix
  ];

  networking = {
    hostName = "rt-sea2";
    domain = globals.zones.home;
    useDHCP = false;
  };

  systemd.network = {
    enable = true;

    links."10-wan0" = {
      matchConfig.Driver = "virtio_net";
      linkConfig.Name = "wan0";
    };

    netdevs = {
      "00-lo0" = {
        netdevConfig = {
          Name = "lo0";
          Kind = "dummy";
        };
      };
      "00-lo53" = {
        netdevConfig = {
          Name = "lo53";
          Kind = "dummy";
        };
      };
    };

    networks = {
      "01-lo0" = {
        name = "lo0";
        address = [ rt-sea2.interfaces.lo0 ];
        networkConfig = {
          DNS = rt-sea2.interfaces.lo0;
          Domains = "~.";
        };
      };
      "01-lo53" = {
        name = "lo53";
        # address is managed by the anycast-health gate (see services/dns.nix)
        networkConfig.LinkLocalAddressing = "no";
        linkConfig.RequiredForOnline = "no";
      };
      "02-wan0" = {
        name = "wan0";
        networkConfig = {
          DHCP = "yes";
        };
        dhcpV4Config = {
          UseDNS = false;
        };
      };
    };
  };
}
