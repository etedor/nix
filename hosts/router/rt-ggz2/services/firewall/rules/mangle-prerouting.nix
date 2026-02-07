{
  globals,
  ...
}:

let
  net = globals.networks;
in

# ------------------------------------------------------------------------------
# PBR: restore conntrack mark to fwmark for return routing
#
# logic:
#   - for packets with non-RFC1918 destination and ct mark bits 3-0 != 0,
#     restore the PBR tunnel ID from ct mark to fwmark so FRR's PBR map
#     can route return traffic back out the correct WG tunnel.
#
# DSCP restoration for inbound return traffic
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
#   - PBR tunnel ID (bits 3-0) is not affected.
#
# mark layout:
#   [ 31-26 | DSCP value ] [ 25 | unused ] [ 24 | valid flag ]
#   [ 23-4 | reserved ] [ 3-0 | PBR tunnel ID ]
#
# example:
#   - ct mark 0x21000000 -> restore DSCP CS1 (bulk traffic)
#   - ct mark 0x01000000 -> restore DSCP CS0 (besteffort traffic)
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
  rules =
    # PBR: restore ct mark bits 3-0 to fwmark for non-RFC1918 dst
    [
      {
        name = "pbr restore fwmark";
        dips = net.non-rfc1918;
        expr = "ct mark & 0x0000000f != 0 meta mark set ct mark & 0x0000000f";
        action = "continue";
      }
    ]
    # DSCP: restore from ct mark bits 31-26 on established connections
    ++ builtins.map (m: {
      name = "dscp ${m.name} ct in";
      expr = "ct state established ct mark & 0xff000000 == ${m.mark} ip dscp set ${m.dscp}";
      action = "accept";
    }) dscpRestoreMarks;
}
