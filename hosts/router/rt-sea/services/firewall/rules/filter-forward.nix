{
  net,
  ...
}:

let
  zoneTrust = [
    "wg0"
    "wg1"
  ];
in
{
  rules = [
    {
      name = "trust to trust";
      iifs = zoneTrust;
      oifs = zoneTrust;
      action = "accept";
    }
    {
      name = "wg1 to internet";
      sips = [ net.sea.wg1 ];
      dips = [ "0.0.0.0/0" ];
      action = "accept";
    }
  ];
}
