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
    domain = globals.zone;
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
    };

    networks = {
      "01-lo0" = {
        name = "lo0";
        address = [ rt-sea2.interfaces.lo0 ];
      };
      "02-wan0" = {
        name = "wan0";
        networkConfig = {
          DHCP = "yes";
        };
      };
    };
  };
}
