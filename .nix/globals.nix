{ private }:

let
  ggz = {
    infra = "10.0.2.0/24";
    server = "10.0.4.0/24";
    clients = "10.0.8.0/23";
    trust3 = "10.0.8.0/24";
    trust2 = "10.0.9.0/24";
    trust2-upnp = "10.0.9.32/27";
    trust2-sonos = "10.0.9.64/27";
    things = "10.0.10.0/23";
    trust1 = "10.0.10.0/24";
    trust1-isolate = "10.0.10.32/27";
    trust0 = "10.0.11.0/24";
    guest = "10.0.16.0/24";
    lab = "10.0.32.0/24";
    mgmt = "192.168.0.0/24";
  };

  sea = {
    wg0 = "10.100.0.0/31";
    wg10 = "10.100.10.0/24";
    wg11 = "10.100.11.0/24";
  };

  travel = {
    lan = "10.99.1.0/24";
    family = "10.99.1.0/24";
  };
in
{
  globals = {
    keys = import ./keys.nix;
    users = i: builtins.elemAt private.users i;

    jumbo = 9198;
    tz = "America/Los_Angeles";
    zone = private.zone;

    hosts = {
      brother = {
        name = "brother.${private.zone}";
        ip = "10.0.11.16";
      };
      duke = {
        name = "duke.${private.zone}";
        ip = "10.0.4.32";
      };
      home-assistant = {
        name = "home-assistant.${private.zone}";
        ip = "10.0.8.16";
      };
      machina = {
        name = "machina.${private.zone}";
        ip = "10.0.8.32";
      };
      ntp = {
        name = "ntp.${private.zone}";
        ip = "10.0.2.16";
      };
    };

    networks = {
      rfc1918 = [
        "10.0.0.0/8"
        "172.16.0.0/12"
        "192.168.0.0/16"
      ];

      non-rfc1918 = [
        "!10.0.0.0/8"
        "!172.16.0.0/12"
        "!192.168.0.0/16"
      ];

      admin = [
        ggz.trust3
        sea.wg10
      ];

      family = [
        ggz.trust2
        sea.wg11
        travel.family
      ];

      inherit ggz sea travel;
    };

    routers = {
      rt-ggz = {
        localAs = 65000;
        interfaces = {
          lo0 = "10.127.0.1";
          wg0 = "10.100.0.1";
        };
      };
      rt-sea = {
        extIntf = "ens3";
        localAs = 65100;
        interfaces = {
          ens3 = "66.42.69.91";
          lo0 = "10.127.100.1";
          wg0 = "10.100.0.0";
        };
        zones = {
          p2p = [ "wg0" ];
          sea-admin = [ "wg10" ];
          sea-family = [ "wg11" ];
          untrust = [ "ens3" ];
        };
      };
    };
  };
}
