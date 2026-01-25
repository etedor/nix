{
  zone,
  ...
}:

{
  rules = [
    {
      name = "https to duke";
      iifs = zone.untrust;
      ip = "10.0.4.32"; # TODO: use globals.hosts reference
      pt = 443;
      proto = "tcp";
    }
  ];
}
