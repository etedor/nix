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
        "ens3"
      ];
    }
  ];
}
