{
  globals,
  ...
}:

let
  net = globals.networks;

  extIntf = "wan0";
  intIntf = [ "vlan8" ];
in
{
  et42.router.miniupnpd = {
    enable = true;
    natpmp = true;
    upnp = true;

    uuid = "9d9d00e1-d6c8-432c-ac4e-c57503d43ced";
    serial = "RT-GGZ-R86S";
    systemUptime = true;

    externalInterface = extIntf;
    internalIPs = intIntf;

    permissionRules = [
      {
        action = "allow";
        prefix = net.ggz.trust2-upnp;
      }
    ];
  };

  et42.router.nftables.extraFilterInputRules = [
    {
      name = "upnp ssdp";
      iifs = intIntf;
      proto = "udp";
      dpts = [ 1900 ];
      action = "accept";
    }
    {
      name = "upnp http";
      iifs = intIntf;
      proto = "tcp";
      dpts = [ 2869 ];
      action = "accept";
    }
    {
      name = "nat-pmp";
      iifs = intIntf;
      proto = "udp";
      dpts = [ 5351 ];
      action = "accept";
    }
  ];
}
