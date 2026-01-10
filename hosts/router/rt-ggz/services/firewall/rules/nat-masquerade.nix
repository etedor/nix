{
  net,
  ...
}:

{
  rules = [
    {
      name = "masquerade";
      sips = net.rfc1918;
      oifs = [
        "wan0"
        "wan1"
      ];
    }
  ];
}
