# policy-based routing for return traffic via WG tunnels
#
# tunnel IDs stored in ct mark bits 3-0:
#   0 = no PBR (normal routing)
#   1 = wg0 (rt-ggz)
#   2 = wg1 (rt-ggz2)
#   3 = wg2 (rt-sea2)
{
  globals,
  lib,
  ...
}:

let
  net = globals.networks;

  pbrMapName = "RETURN";
  nhg0 = "ONPREM-WG0";
  nhg1 = "ONPREM-WG1";
  nhg2 = "VPS-WG2";
in
{
  et42.router.nftables = {
    extraManglePreRoutingRules = lib.mkBefore [
      {
        name = "restore-conntrack-mark-for-public";
        dips = net.non-rfc1918;
        expr = "ct mark & 0x0f != 0";
        action = "meta mark set ct mark and 0x0f";
      }
    ];
    extraMangleForwardRules = [
      {
        name = "mark-internet-via-wg0";
        iifs = [ "wg0" ];
        sips = net.non-rfc1918;
        expr = "ct state new";
        action = "ct mark set (ct mark & 0xfffffff0 | 1)";
      }
      {
        name = "mark-internet-via-wg1";
        iifs = [ "wg1" ];
        sips = net.non-rfc1918;
        expr = "ct state new";
        action = "ct mark set (ct mark & 0xfffffff0 | 2)";
      }
      {
        name = "mark-internet-via-wg2";
        iifs = [ "wg2" ];
        sips = net.non-rfc1918;
        expr = "ct state new";
        action = "ct mark set (ct mark & 0xfffffff0 | 3)";
      }
    ];
  };

  services.frr = {
    pbrd.enable = true;
    config = ''
      nexthop-group ${nhg0}
        nexthop 10.100.0.1
      !
      nexthop-group ${nhg1}
        nexthop 10.100.0.3
      !
      nexthop-group ${nhg2}
        nexthop 10.101.0.4
      !
      pbr-map ${pbrMapName} seq 10
        match mark 1
        set nexthop-group ${nhg0}
      !
      pbr-map ${pbrMapName} seq 20
        match mark 2
        set nexthop-group ${nhg1}
      !
      pbr-map ${pbrMapName} seq 30
        match mark 3
        set nexthop-group ${nhg2}
      !
    '';
  };
}
