{
  ...
}:

# ------------------------------------------------------------------------------
# DSCP classification for outbound traffic
#
# logic:
#   - when a packet leaves, classify it based on its DSCP value,
#     and store the actual DSCP value in bits 31-26 of the conntrack mark.
#   - set a valid flag at bit 24 to indicate DSCP is stored.
#
# important:
#   - preserve routing-related mark bits (bits 7-4, e.g., 0x10 for PBR).
#   - clear old DSCP storage (bits 31-24) before writing new value.
#
# expression:
#   - new conntrack mark = (ct mark & 0x00ffffff) | (DSCP << 26) | 0x01000000
#
# mark layout:
#   [ 31-26 | DSCP value ] [ 25 | unused ] [ 24 | valid flag ]
#   [ 23-8 | reserved ] [ 7-4 | routing bits ] [ 3-0 | unused ]
#
# example:
#   - ip DSCP CS1 (8) → ct mark = 0x21000000 | (ct mark & 0x00ffffff)
#   - ip DSCP CS0 (0) → ct mark = 0x01000000 | (ct mark & 0x00ffffff)
#
# for tc-ctinfo compatibility:
#   - tc-ctinfo uses mask 0xfc000000 to extract DSCP from bits 31-26
#   - tc-ctinfo uses statemask 0x01000000 to check valid flag at bit 24
# ------------------------------------------------------------------------------

let
  dscpMarking = [
    {
      name = "bulk";
      dscps = "{ cs1, af11, af12, af13 }";
      mark = "0x21000000"; # cs1 (8 << 26) | valid flag (0x01000000)
    }
    {
      name = "besteffort";
      dscps = "{ cs0, cs2, af21, af22, af23 }";
      mark = "0x01000000"; # cs0 (0 << 26) | valid flag (0x01000000)
    }
    {
      name = "video";
      dscps = "{ cs3, af31, af32, af33, cs4, af41, af42, af43 }";
      mark = "0x61000000"; # cs3 (24 << 26) | valid flag (0x01000000)
    }
    {
      name = "voice";
      dscps = "{ cs5, va, ef, cs6, cs7 }";
      mark = "0xb9000000"; # ef (46 << 26) | valid flag (0x01000000)
    }
  ];

in
{
  rules = builtins.map (m: {
    name = "ct dscp ${m.name} out";
    expr = "ip dscp ${m.dscps} ct mark set ((ct mark & 0x00ffffff) | ${m.mark})";
    action = "accept";
  }) dscpMarking;
}
