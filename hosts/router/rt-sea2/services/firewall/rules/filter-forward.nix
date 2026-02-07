{
  globals,
  ...
}:

let
  net = globals.networks;
in
{
  rules = [
    {
      name = "rfc1918 to rfc1918";
      sips = net.rfc1918;
      dips = net.rfc1918;
      action = "accept";
    }
  ];
}
