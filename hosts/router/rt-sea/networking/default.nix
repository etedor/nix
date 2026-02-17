{
  globals,
  ...
}:

let
  rt-sea = globals.routers.rt-sea;
in
{
  imports = [
    ./tuning.nix
    ./routing
    ./wireguard.nix
  ];

  networking = {
    hostName = "rt-sea";
    domain = globals.zones.home;
    useDHCP = false; # managed by systemd-networkd
  };

  # https://nixos.wiki/wiki/Systemd-networkd
  systemd.network = {
    enable = true;
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
        address = [ rt-sea.interfaces.lo0 ];
        networkConfig = {
          DNS = rt-sea.interfaces.lo0;
          Domains = "~.";
        };
      };
      "01-lo53" = {
        name = "lo53";
        address = [ globals.anycast.dns ];
      };
      "02-ens3" = {
        name = "ens3";
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
