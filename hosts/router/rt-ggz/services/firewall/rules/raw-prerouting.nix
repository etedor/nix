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
    {
      name = "wan1 zone 2";
      oifs = [ "wan1" ];
      action = "ct zone set 2";
    }
  ];
}
