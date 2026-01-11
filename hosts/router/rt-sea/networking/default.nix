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
    ./routing.nix
    ./wireguard.nix
  ];

  networking = {
    hostName = "rt-sea";
    domain = globals.zone;
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
