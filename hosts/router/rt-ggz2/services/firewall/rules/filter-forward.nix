{
  globals,
  ...
}:

let
  net = globals.networks;
in
{
  rules = [
    # mgmt to internet via wan0
    {
      name = "mgmt to internet";
      sips = [ net.ggz2.mgmt ];
      dips = net.non-rfc1918;
      action = "accept";
    }

    # xc0 transit: rt-ggz failover traffic to wan0
    {
      name = "xc0 transit to internet";
      iifs = [ "xc0" ];
      dips = net.non-rfc1918;
      action = "accept";
    }

    # WG tunnel forwarding: xc0 <-> wg0 (transit to VPS)
    {
      name = "xc0 to wg";
      iifs = [ "xc0" ];
      oifs = [ "wg0" ];
      action = "accept";
    }
    {
      name = "wg to xc0";
      iifs = [ "wg0" ];
      oifs = [ "xc0" ];
      action = "accept";
    }

    # mgmt must not reach internal VLANs
    {
      name = "mgmt to rfc1918";
      sips = [ net.ggz2.mgmt ];
      dips = net.rfc1918;
      action = "drop";
      log = true;
    }
  ];
}
