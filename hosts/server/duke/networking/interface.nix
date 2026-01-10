{
  globals,
  ...
}:

{
  networking = {
    hostName = "duke";
    domain = globals.zone;
    useDHCP = false; # managed by systemd-networkd

    firewall.allowedTCPPorts = [ ];
    firewall.allowedUDPPorts = [ ];
    firewall.trustedInterfaces = [
      "bulk0"
      "default0"
      "media0"
    ];
  };

  # https://nixos.wiki/wiki/Systemd-networkd
  systemd.network = {
    enable = true;
    links = {
      "20-lan0p0" = {
        matchConfig.PermanentMACAddress = "e4:1d:2d:7c:59:50";
        linkConfig = {
          Name = "lan0p0";
          MTUBytes = globals.jumbo;
        };
      };
      "21-lan0p1" = {
        matchConfig.PermanentMACAddress = "e4:1d:2d:7c:59:51";
        linkConfig = {
          Name = "lan0p1";
          MTUBytes = globals.jumbo;
        };
      };
    };
    netdevs = {
      "30-lan0" = {
        netdevConfig = {
          Kind = "bond";
          Name = "lan0";
          MTUBytes = globals.jumbo;
        };
        bondConfig = {
          Mode = "802.3ad";
          TransmitHashPolicy = "layer3+4";
          MIIMonitorSec = "1s";
          LACPTransmitRate = "fast";
          MinLinks = 1;
        };
      };
    };
    networks = {
      "20-lan0p0" = {
        matchConfig.Name = "lan0p0";
        networkConfig.Bond = "lan0";
      };
      "21-lan0p1" = {
        matchConfig.Name = "lan0p1";
        networkConfig.Bond = "lan0";
      };
      "30-lan0" = {
        matchConfig.Name = "lan0";
        linkConfig = {
          RequiredForOnline = "carrier";
        };
        networkConfig = {
          Address = [ "10.0.4.32/24" ];
          Gateway = "10.0.4.1";
          DNS = [ "10.127.0.1" ];
          LinkLocalAddressing = "no";
        };
      };
    };
  };
}
