{
  globals,
  ...
}:

let
  net = globals.networks;

  hosts = globals.hosts;
  brother = hosts.brother;
  duke = hosts.duke;
  home-assistant = hosts.home-assistant;
  machina = hosts.machina;
  ntp = hosts.ntp;

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

    # drop any to trust1-isolate
    {
      name = "any to trust1-isolate";
      sips = net.rfc1918;
      dips = [ net.ggz.trust1-isolate ];
      action = "drop";
      log = true;
    }

    # allow rfc1918 to services
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
      dips = [ rt-sea.interfaces.lo0 ];
      dpts = [
        53
        5353
      ];
      proto = [
        "tcp"
        "udp"
      ];
      action = "accept";
      log = false;
    }

    # server rules
    {
      name = "servers to internet";
      sips = [ net.ggz.server ];
      dips = net.non-rfc1918;
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
      name = "dnat to duke";
      iifs = [ "wg0" ];
      sips = net.non-rfc1918;
      dips = [ duke.ip ];
      dpts = [ 443 ];
      proto = "tcp";
      action = "accept";
      log = true;
    }
    {
      name = "duke to machina";
      sips = [ duke.ip ];
      dips = [ machina.ip ];
      dpts = [ 5678 ];
      proto = "tcp";
      action = "accept";
      log = true;
    }
    {
      name = "duke to home-assistant";
      sips = [ duke.ip ];
      dips = [ home-assistant.ip ];
      dpts = [ 1880 8123 ];
      proto = "tcp";
      action = "accept";
      log = true;
    }

    {
      name = "things to home-assistant";
      sips = [ net.ggz.things ];
      dips = [ home-assistant.ip ];
      action = "accept";
      log = true;
    }
    {
      name = "home-assistant to things";
      sips = [ home-assistant.ip ];
      dips = [ net.ggz.things ];
      action = "accept";
      log = true;
    }

    # admin rules
    {
      name = "admin to rfc1918";
      sips = net.admin;
      dips = net.rfc1918;
      action = "accept";
    }
    {
      name = "admin to any";
      sips = net.admin;
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
      name = "family to trust2";
      sips = net.family;
      dips = [ net.ggz.trust2 ];
      action = "accept";
      log = true;
    }
    {
      name = "family to trust1";
      sips = net.family;
      dips = [ net.ggz.trust1 ];
      action = "accept";
      log = true;
    }
    {
      name = "family to trust0";
      sips = net.family;
      dips = [ net.ggz.trust0 ];
      action = "accept";
      log = true;
    }

    {
      name = "family to server";
      sips = net.family;
      dips = [ net.ggz.server ];
      action = "accept";
      log = true;
    }

    {
      name = "family to rfc1918";
      sips = net.family;
      dips = net.rfc1918;
      action = "drop";
      log = true;
    }
    {
      name = "family to any";
      sips = net.family;
      dips = [ "0.0.0.0/0" ];
      action = "accept";
    }

    # things rules
    {
      name = "things to dot";
      sips = [ net.ggz.things ];
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
      sips = [ brother.ip ];
      dips = [ duke.ip ];
      dpts = [ 445 ];
      action = "accept";
      log = true;
    }
    {
      name = "clients to brother";
      sips = net.admin ++ net.family;
      dips = [ brother.ip ];
      action = "accept";
      log = true;
    }
    {
      name = "brother to clients";
      sips = [ brother.ip ];
      dips = net.admin ++ net.family;
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
