{ private }:

{
  globals = {
    keys = import ./keys.nix;
    users = i: builtins.elemAt private.users i;

    jumbo = 9198;
    tz = "America/Los_Angeles";
    zone = private.zone;

    hosts = {
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

      ggz = {
        infra = "10.0.2.0/24";
        server = "10.0.4.0/24";
        trust3 = "10.0.8.0/24";
        trust2 = "10.0.9.0/24";
        trust2-upnp = "10.0.9.32/27";
        trust2-sonos = "10.0.9.64/27";
        trust10 = "10.0.10.0/23";
        trust1 = "10.0.10.0/24";
        trust1-isolate = "10.0.10.32/27";
        trust0 = "10.0.11.0/24";
        guest = "10.0.16.0/24";
        lab = "10.0.32.0/24";
        mgmt = "192.168.0.0/24";
      };

      sea = {
        wg0 = "10.99.0.0/31";
        wg1 = "10.99.1.0/24";
      };
    };

    routers = {
      rt-ggz = {
        localAs = 65000;
        interfaces = {
          lo0 = "10.127.0.1";
          wg0 = "10.99.0.1";
        };
      };
      rt-sea = {
        extIntf = "ens3";
        localAs = 65099;
        interfaces = {
          ens3 = "66.42.69.91";
          lo0 = "10.127.99.1";
          wg0 = "10.99.0.0";
        };
      };
    };
  };
}
