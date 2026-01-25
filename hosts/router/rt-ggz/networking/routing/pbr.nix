# policy-based routing for non-RFC1918 return traffic via WG tunnels
#
# tunnel IDs are stored in ct mark bits 0-3:
# mark = tunnel ID + 1
#   0 = no PBR (normal routing)
#   1 = wg0
#   2 = wg1
#   ...
{
  globals,
  lib,
  ...
}:

let
  net = globals.networks;
  rt-sea = globals.routers.rt-sea;

  pbrMapName = "VPS-RETURN";
  nhgName = "VPS-WG0";
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
        action = "ct mark set (ct mark & 0xfffffff0 | 1)"; # preserve all bits except 0-3
      }
    ];
  };

  services.frr = {
    pbrd.enable = true;
    config = ''
      nexthop-group ${nhgName}
        nexthop ${rt-sea.interfaces.wg0}
      !
      pbr-map ${pbrMapName} seq 10
        match mark 1
        set nexthop-group ${nhgName}
      !
      interface vlan4
        pbr-policy ${pbrMapName}
    '';
  };
}
