{
  globals,
  ...
}:

let
  net = globals.networks;
  ntp = globals.hosts.ntp;
  rt-ggz = globals.routers.rt-ggz;

  iotIntercept = {
    iifs = [ "vlan8" ];
    sips = [
      net.ggz.trust1
      net.ggz.trust0
    ];
    dips = net.non-rfc1918;
    log = true;
  };
in
{
  rules = [
    {
      name = "dns redirect";
      inherit (iotIntercept)
        iifs
        # oifs
        sips
        dips
        log
        ;
      ip = rt-ggz.interfaces.lo0;
      pt = 53;
      proto = "udp";
    }
    {
      name = "dns redirect";
      inherit (iotIntercept)
        iifs
        # oifs
        sips
        dips
        log
        ;
      ip = rt-ggz.interfaces.lo0;
      pt = 53;
      proto = "tcp";
    }

    {
      name = "ntp redirect";
      iifs = [ "vlan8" ];
      sips = [
        net.ggz.trust3
        net.ggz.trust2
        net.ggz.trust1
        net.ggz.trust0
      ];
      dips = net.non-rfc1918;
      ip = ntp.ip;
      pt = 123;
      proto = "udp";
      log = true;
    }
  ];
}
