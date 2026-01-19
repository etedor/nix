{
  globals,
  net,
  ...
}:

let
  ntp = globals.hosts.ntp;
  rt-sea = globals.routers.rt-sea;
in
{
  rules = [
    # infra rules
    {
      name = "infra to server";
      sips = [ net.ggz.infra ];
      dips = [ net.ggz.server ];
      action = "accept";
      log = true;
    }
    {
      name = "infra to any";
      sips = [ net.ggz.infra ];
      dips = [ "0.0.0.0/0" ];
      action = "accept";
    }

    # allow ICMP from RFC1918 to RFC1918
    {
      name = "rfc1918 to rfc1918";
      sips = net.rfc1918;
      dips = net.rfc1918;
      action = "accept";
      proto = "icmp";
    }

    # drop any to trust1-isolate
    {
      name = "any to trust1-isolate";
      sips = net.rfc1918;
      dips = [ net.ggz.trust1-isolate ];
      action = "drop";
      log = true;
    }

    # allow rfc1918 to ntp
    {
      name = "rfc1918 to ntp";
      sips = net.rfc1918;
      dips = [ ntp.ip ];
      dpts = [ 123 ];
      proto = "udp";
      action = "accept";
      log = false;
    }
    {
      name = "rfc1918 to dns";
      sips = net.rfc1918;
      dips = net.rfc1918; # TODO: restrict to DNS servers only
      dpts = [ 53 ];
      proto = "udp";
      action = "accept";
      log = false;
    }

    # server rules
    {
      name = "servers to any";
      sips = [ net.ggz.server ];
      dips = [ "0.0.0.0/0" ];
      action = "accept";
    }
    {
      name = "servers to infra";
      sips = [ net.ggz.server ];
      dips = [ net.ggz.infra ];
      action = "accept";
      log = true;
    }

    {
      name = "peer-admin to infra";
      sips = [ net.sea.wg10 ];
      dips = [ net.ggz.infra ];
      action = "accept";
      log = true;
    }
    {
      name = "peer-admin to server";
      sips = [ net.sea.wg10 ];
      dips = [ net.ggz.server ];
      action = "accept";
      log = true;
    }
    {
      name = "peer-admin to rfc1918";
      sips = [ net.sea.wg10 ];
      dips = net.rfc1918;
      action = "drop";
      log = true;
    }

    {
      name = "clients to home-assistant";
      sips = [ "10.0.8.0/22" ];
      dips = [ "10.0.8.16" ];
      action = "accept";
      log = true;
    }

    # trust3 rules
    {
      name = "trust3 to trust3";
      sips = [ net.ggz.trust3 ];
      dips = [ net.ggz.trust3 ];
      action = "accept";
      log = true;
    }
    {
      name = "trust3 to trust2";
      sips = [ net.ggz.trust3 ];
      dips = [ net.ggz.trust2 ];
      action = "accept";
      log = true;
    }
    {
      name = "trust3 to trust1";
      sips = [ net.ggz.trust3 ];
      dips = [ net.ggz.trust1 ];
      action = "accept";
      log = true;
    }
    {
      name = "trust3 to trust0";
      sips = [ net.ggz.trust3 ];
      dips = [ net.ggz.trust0 ];
      action = "accept";
      log = true;
    }

    {
      name = "trust3 to modems";
      sips = [ net.ggz.trust3 ];
      dips = [
        "192.168.100.1"
        "192.168.12.1"
      ];
      dpts = [
        80
        443
      ];
      action = "accept";
      log = true;
    }
    {
      name = "trust3 to infra";
      sips = [ net.ggz.trust3 ];
      dips = [ net.ggz.infra ];
      action = "accept";
      log = true;
    }
    {
      name = "trust3 to server";
      sips = [ net.ggz.trust3 ];
      dips = [ net.ggz.server ];
      action = "accept";
      log = true;
    }
    {
      name = "trust3 to lab";
      sips = [ net.ggz.trust3 ];
      dips = [ net.ggz.lab ];
      action = "accept";
      log = true;
    }
    {
      name = "trust3 to rt-sea";
      sips = [ net.ggz.trust3 ];
      dips = [ rt-sea.interfaces.lo0 ];
      action = "accept";
      log = true;
    }

    {
      name = "trust3 to rfc1918";
      sips = [ net.ggz.trust3 ];
      dips = net.rfc1918;
      action = "accept";
      log = true;
    }
    {
      name = "trust3 to any";
      sips = [ net.ggz.trust3 ];
      dips = [ "0.0.0.0/0" ];
      action = "accept";
    }

    # trust2 rules
    {
      name = "trust2-upnp to trust2-upnp";
      sips = [ net.ggz.trust2-upnp ];
      dips = [ net.ggz.trust2-upnp ];
      action = "accept";
      log = true;
    }
    {
      name = "trust2-upnp to server";
      sips = [ net.ggz.trust2-upnp ];
      dips = [ net.ggz.server ];
      dpts = [
        80
        443
      ];
      proto = "tcp";
      action = "accept";
      log = true;
    }
    {
      name = "trust2-upnp to rfc1918";
      sips = [ net.ggz.trust2-upnp ];
      dips = net.rfc1918;
      action = "drop";
      log = true;
    }

    {
      name = "trust2 to trust2";
      sips = [ net.ggz.trust2 ];
      dips = [ net.ggz.trust2 ];
      action = "accept";
      log = true;
    }
    {
      name = "trust2 to trust1";
      sips = [ net.ggz.trust2 ];
      dips = [ net.ggz.trust1 ];
      action = "accept";
      log = true;
    }
    {
      name = "trust2 to trust0";
      sips = [ net.ggz.trust2 ];
      dips = [ net.ggz.trust0 ];
      action = "accept";
      log = true;
    }

    {
      name = "trust2 to server";
      sips = [ net.ggz.trust2 ];
      dips = [ net.ggz.server ];
      action = "accept";
      log = true;
    }

    {
      name = "trust2 to rfc1918";
      sips = [ net.ggz.trust2 ];
      dips = net.rfc1918;
      action = "drop";
      log = true;
    }
    {
      name = "trust2 to any";
      sips = [ net.ggz.trust2 ];
      dips = [ "0.0.0.0/0" ];
      action = "accept";
    }

    # trust10 rules
    {
      name = "trust10 to dot";
      sips = [ net.ggz.trust10 ];
      dpts = [ 853 ];
      proto = "tcp";
      action = "drop";
      log = true;
    }

    # trust1 rules
    {
      name = "trust1-isolate to rfc1918";
      sips = [ net.ggz.trust1-isolate ];
      dips = net.rfc1918;
      action = "drop";
      log = true;
    }

    {
      name = "trust1 to trust1";
      sips = [ net.ggz.trust1 ];
      dips = [ net.ggz.trust1 ];
      action = "accept";
      log = true;
    }
    {
      name = "trust1 to trust0";
      sips = [ net.ggz.trust1 ];
      dips = [ net.ggz.trust0 ];
      action = "accept";
      log = true;
    }

    {
      name = "trust1 to rfc1918";
      sips = [ net.ggz.trust1 ];
      dips = net.rfc1918;
      action = "drop";
      log = true;
    }
    {
      name = "trust1 to any";
      sips = [ net.ggz.trust1 ];
      dips = [ "0.0.0.0/0" ];
      action = "accept";
      log = true;
    }

    # trust0 rules
    {
      name = "trust0 to trust0";
      sips = [ net.ggz.trust0 ];
      dips = [ net.ggz.trust0 ];
      action = "accept";
      log = true;
    }

    {
      name = "brother to paperless";
      sips = [ "10.0.11.16" ]; # TODO: use et42.hosts reference for brother printer
      dips = [ "10.0.4.32" ]; # TODO: use et42.hosts reference for paperless
      dpts = [ 445 ];
      action = "accept";
      log = true;
    }
    {
      name = "clients to brother";
      sips = [ "10.0.8.0/22" ];
      dips = [ "10.0.11.16" ]; # TODO: use et42.hosts reference
      action = "accept";
      log = true;
    }
    {
      name = "brother to clients";
      sips = [ "10.0.11.16" ]; # TODO: use et42.hosts reference
      dips = [ "10.0.8.0/22" ];
      action = "accept";
      log = true;
    }

    {
      name = "trust0 to any";
      sips = [ net.ggz.trust0 ];
      dips = [ "0.0.0.0/0" ];
      action = "drop";
      log = true;
    }

    # guest rules
    {
      name = "guest to rfc1918";
      sips = [ net.ggz.guest ];
      dips = net.rfc1918;
      action = "drop";
      log = true;
    }
    {
      name = "guest to internet";
      sips = [ net.ggz.guest ];
      dips = [ "0.0.0.0/0" ];
      action = "accept";
    }

    # lab rules
    {
      name = "lab to rfc1918";
      sips = [ net.ggz.lab ];
      dips = net.rfc1918;
      action = "drop";
      log = true;
    }
    {
      name = "lab to internet";
      sips = [ net.ggz.lab ];
      dips = [ "0.0.0.0/0" ];
      action = "accept";
      log = true;
    }

    # management rules
    {
      name = "management to any";
      sips = [ net.ggz.mgmt ];
      dips = [ "0.0.0.0/0" ];
      action = "drop";
      log = true;
    }
  ];
}
