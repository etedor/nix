{ ... }:

let
  # MSS clamping rules for IPv4 only
  mssClampExpr = "tcp flags & syn != 0 tcp option maxseg size set";
  mssClampRules = [
    {
      name = "mss clamp";
      expr = "${mssClampExpr} rt mtu";
      action = "continue";
    }
  ];
in
{
  rules = mssClampRules;
}
