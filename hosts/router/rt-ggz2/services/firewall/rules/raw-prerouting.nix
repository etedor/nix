{
  ...
}:

{
  rules = [
    {
      name = "wan0 zone 1";
      oifs = [ "wan0" ];
      action = "ct zone set 1";
    }
  ];
}
