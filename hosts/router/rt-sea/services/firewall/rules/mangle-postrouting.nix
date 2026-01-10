{
  wg,
  ...
}:

let
  mssClampExpr = "tcp flags & (syn | rst) == syn tcp option maxseg size set";
in
{
  rules = [
    {
      name = "mss clamp wireguard";
      oifs = wg.interfaces;
      expr = "${mssClampExpr} 1380";
      action = "continue";
    }
  ];
}
