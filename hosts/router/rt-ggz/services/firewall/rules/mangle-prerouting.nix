{
  net,
  ...
}:

# ------------------------------------------------------------------------------
# DSCP restoration for inbound return traffic (defense-in-depth)
#
# logic:
#   - if a connection is established and has a DSCP value stored
#     in bits 31-26 of the conntrack mark with valid flag at bit 24,
#     restore the appropriate DSCP value on the packet.
#
# important:
#   - this provides defense-in-depth: tc-ctinfo already restores DSCP
#     at TC ingress (before CAKE), but this ensures DSCP is correct
#     even if TC rules fail or are bypassed.
#   - routing marks (bits 7-4, e.g., 0x10 for PBR) are not affected.
#
# mark layout:
#   [ 31-26 | DSCP value ] [ 25 | unused ] [ 24 | valid flag ]
#   [ 23-8 | reserved ] [ 7-4 | routing bits ] [ 3-0 | unused ]
#
# example:
#   - ct mark 0x21000000 → restore DSCP CS1 (bulk traffic)
#   - ct mark 0x01000000 → restore DSCP CS0 (besteffort traffic)
# ------------------------------------------------------------------------------

let
  dscpRestoreMarks = [
    {
      name = "bulk";
      mark = "0x21000000"; # cs1 (8 << 26) | valid flag (0x01000000)
      dscp = "cs1";
    }
    {
      name = "besteffort";
      mark = "0x01000000"; # cs0 (0 << 26) | valid flag (0x01000000)
      dscp = "cs0";
    }
    {
      name = "video";
      mark = "0x61000000"; # cs3 (24 << 26) | valid flag (0x01000000)
      dscp = "cs3";
    }
    {
      name = "voice";
      mark = "0xb9000000"; # ef (46 << 26) | valid flag (0x01000000)
      dscp = "ef";
    }
  ];
in
{
  rules = [
    # gaming traffic counter for CAKE dynamic bandwidth adjustment
    # count EF-marked packets from gaming prefix to internet before DSCP restoration
    # prevents us from counting ingress traffic from WAN that comes in already marked
    {
      name = "count game traffic";
      sips = [ net.ggz.trust2-upnp ];
      dips = [ "!\$RFC_1918" ];
      expr = "ip dscp ef counter name game_traffic";
      action = "continue";
    }
  ]
  ++ builtins.map (m: {
    name = "dscp ${m.name} ct in";
    expr = "ct state established ct mark & 0xff000000 == ${m.mark} ip dscp set ${m.dscp}";
    action = "accept";
  }) dscpRestoreMarks;
}
