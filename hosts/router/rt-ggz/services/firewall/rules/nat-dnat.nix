{
  config,
  net,
  ...
}:

let
  ntp = config.et42.hosts.ntp;

  iotIntercept = {
    iifs = [ "vlan8" ];
    sips = [
      net.ggz.trust1
      net.ggz.trust0
    ];
    dips = [ "!$RFC_1918" ];
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
      ip = "10.127.0.1"; # TODO: use et42.hosts reference
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
      ip = "10.127.0.1"; # TODO: use et42.hosts reference
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
      dips = [ "!$RFC_1918" ];
      ip = ntp.ip;
      pt = 123;
      proto = "udp";
      log = true;
    }
  ];
}
